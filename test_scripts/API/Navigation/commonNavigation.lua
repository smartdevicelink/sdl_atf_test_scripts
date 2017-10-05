---------------------------------------------------------------------------------------------------
-- Navigation common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local json = require("modules/json")

local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local SDL = require('SDL')

local mobile_api_loader = require("modules/api_loader")
local mobile_api = mobile_api_loader.init("data/MOBILE_API.xml")
local mobile_api_schema = mobile_api.interface["Ford Sync RAPI"]

local hmi_api_loader = require("modules/api_loader")
local hmi_api = hmi_api_loader.init("data/HMI_API.xml")
local hmi_api_schema = hmi_api.interface["Common"]

--[[ Variables ]]
local ptu_table = {}
local hmiAppIds = {}
local commonNavigation = {}

local successCodes = {
  "SUCCESS",
  "WARNINGS",
  "WRONG_LANGUAGE",
  "RETRY",
  "SAVED"
}

local notification = {
  wayPoints = {
    {
      coordinate = {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      }
    }
  }
}

commonNavigation.timeout = 2000
commonNavigation.minTimeout = 500
commonNavigation.DEFAULT = "Default"

--[[ Functions ]]

--[[ @checkIfPTSIsSentAsBinary: check if binary data is not empty
--! @parameters:
--! pBinData - binary data
--]]
local function checkIfPTSIsSentAsBinary(pBinData)
  if not (pBinData ~= nil and string.len(pBinData) > 0) then
    commonFunctions:userPrint(31, "PTS was not sent to Mobile in payload of OnSystemRequest")
  end
end

--[[ @getGetWayPointsConfig: create configuration for application
-- with additional functional group for Navigation RPCs
--! @parameters: none
--! @return: table with configuration
--]]
function commonNavigation.getGetWayPointsConfig()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "WayPoints" }
  }
end

--[[ @getPTUFromPTS: create policy table update table (PTU)
--! @parameters:
--! pTbl - table with policy table snapshot (PTS)
--! @return: table with PTU
--]]
local function getPTUFromPTS(pTbl)
  pTbl.policy_table.consumer_friendly_messages.messages = nil
  pTbl.policy_table.device_data = nil
  pTbl.policy_table.module_meta = nil
  pTbl.policy_table.usage_and_error_counts = nil
  pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pTbl.policy_table.module_config.preloaded_pt = nil
  pTbl.policy_table.module_config.preloaded_date = nil
end

--[[ @jsonFileToTable: convert .json file to table
--! @parameters:
--! pFileName - file name
--! @return: table
--]]
local function jsonFileToTable(pFileName)
  local f = io.open(pFileName, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

--[[ @tableToJsonFile: convert table to .json file
--! @parameters:
--! pTbl - table
--! pFileName - file name
--]]
local function tableToJsonFile(pTbl, pFileName)
  local f = io.open(pFileName, "w")
  f:write(json.encode(pTbl))
  f:close()
end

--[[ @updatePTU: update PTU table with additional functional group for Navigation RPCs
--! @parameters:
--! pTbl - PTU table
--! pAppId - application number (1, 2, etc.)
--]]
local function updatePTU(pTbl, pAppId)
  pTbl.policy_table.functional_groupings["WayPoints"] = {
    rpcs = {
      GetWayPoints = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      SubscribeWayPoints = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      UnsubscribeWayPoints = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      },
      OnWayPointChange = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      }
    }
  }
  local appID = commonNavigation.getMobileAppId(pAppId)
  pTbl.policy_table.app_policies[appID] = commonNavigation.getGetWayPointsConfig()
end

--[[ @ptu: perform policy table update
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pPTUpdateFunc - additional function for update
--! self - test object
--]]
local function ptu(pAppId, pPTUpdateFunc, self)
  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name })
      getPTUFromPTS(ptu_table)

      updatePTU(ptu_table, pAppId)

      if pPTUpdateFunc then
        pPTUpdateFunc(ptu_table)
      end

      tableToJsonFile(ptu_table, ptu_file_name)

      local event = events.Event()
      event.matches = function(self, e) return self == e end
      EXPECT_EVENT(event, "PTU event")
      :Timeout(11000)

      local function getAppsCount()
        local count = 0
        for _ in pairs(hmiAppIds) do
          count = count + 1
        end
        return count
      end
      for id = 1, getAppsCount() do
        local mobileSession = commonNavigation.getMobileSession(id, self)
        mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_, d2)
            print("App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            checkIfPTSIsSentAsBinary(d2.binaryData)
            local corIdSystemRequest = mobileSession:SendRPC("SystemRequest",
              { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                self.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                  { policyfile = policy_file_path .. "/" .. policy_file_name })
              end)
            mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
          end)
        :Times(AtMost(1))
      end
    end)
  os.remove(ptu_file_name)
end

--[[ @preconditions: precondition steps
--! @parameters: none
--]]
function commonNavigation.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

--[[ @activateApp: activate application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function commonNavigation.activateApp(pAppId, self)
  self, pAppId = commonNavigation.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
  local mobSession = commonNavigation.getMobileSession(pAppId, self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  commonTestCases:DelayedExp(commonNavigation.minTimeout)
end

--[[ @getSelfAndParams: shifting parameters in order to move self at 1st position
--! @parameters:
--! ... - various parameters and self
--! @return: self and other parameters
--]]
function commonNavigation.getSelfAndParams(...)
  local out = { }
  local selfIdx = nil
  for i,v in pairs({...}) do
    if type(v) == "table" and v.isTest then
      table.insert(out, v)
      selfIdx = i
      break
    end
  end
  local idx = 2
  for i = 1, table.maxn({...}) do
    if i ~= selfIdx then
      out[idx] = ({...})[i]
      idx = idx + 1
    end
  end
  return table.unpack(out, 1, table.maxn(out))
end

--[[ @getHMIAppId: get HMI application identifier
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier
--]]
function commonNavigation.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
end

--[[ @getMobileSession: get mobile session
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--! @return: mobile session
--]]
function commonNavigation.getMobileSession(pAppId, self)
  if not pAppId then pAppId = 1 end
  return self["mobileSession" .. pAppId]
end

--[[ @getMobileAppId: get mobile session
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: mobile session
--]]
function commonNavigation.getMobileAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams.appID
end

--[[ @getPathToSDL: get path to SDL binaries
--! @parameters: none
--! @return: path to SDL binaries
--]]
function commonNavigation.getPathToSDL()
  return config.pathToSDL
end

--[[ @postconditions: postcondition steps
--! @parameters: none
--]]
function commonNavigation.postconditions()
  StopSDL()
end

--[[ @registerAppWithPTU: register mobile application and perform PTU
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pPTUpdateFunc - additional function for update
--! self - test object
--]]
function commonNavigation.registerAppWithPTU(pAppId, pPTUpdateFunc, self)
  self, pAppId, pPTUpdateFunc = commonNavigation.getSelfAndParams(pAppId, pPTUpdateFunc, self)
  if not pAppId then pAppId = 1 end
  self["mobileSession" .. pAppId] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. pAppId]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. pAppId]:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID] = d1.params.application.appID
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
            { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
          :Times(3)
          EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptu_table = jsonFileToTable(d2.params.file)
              ptu(pAppId, pPTUpdateFunc, self)
            end)
        end)
      self["mobileSession" .. pAppId]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. pAppId]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(1)
          self["mobileSession" .. pAppId]:ExpectNotification("OnPermissionsChange")
          :Times(AtLeast(1)) -- TODO: Change to exact 1 occurence when SDL issue is fixed
        end)
    end)
end

--[[ @raiN: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function commonNavigation.raiN(pAppId, self)
  self, pAppId = commonNavigation.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  self["mobileSession" .. pAppId] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. pAppId]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. pAppId]:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID] = d1.params.application.appID
        end)
      self["mobileSession" .. pAppId]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. pAppId]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(1)
          self["mobileSession" .. pAppId]:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ @registerAppWithTheSameHashId: register mobile application with the same hash id
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function commonNavigation.registerAppWithTheSameHashId(pAppId, self)
  self, pAppId = commonNavigation.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  self["mobileSession" .. pAppId] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. pAppId]:StartService(7)
  :Do(function()
      config["application" .. pAppId].registerAppInterfaceParams.hashID = self.currentHashID
      local corId = self["mobileSession" .. pAppId]:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID] = d1.params.application.appID
        end)
      self["mobileSession" .. pAppId]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. pAppId]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(1)
          self["mobileSession" .. pAppId]:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ @allowSDL: sequence that allows SDL functionality
--! @parameters:
--! self - test object
--]]
local function allowSDL(self)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    { allowed = true, source = "GUI", device = { id = config.deviceMAC, name = "127.0.0.1" } })
end

--[[ @start: starting sequence: starting of SDL, initialization of HMI, connect mobile
--! @parameters:
--! pHMIParams - table with parameters for HMI initialization
--! self - test object
--]]
function commonNavigation.start(pHMIParams, self)
  self, pHMIParams = commonNavigation.getSelfAndParams(pHMIParams, self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      self:initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady(pHMIParams)
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              self:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                  allowSDL(self)
                end)
            end)
        end)
    end)
end

--[[ @unregisterApp: unregister mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function commonNavigation.unregisterApp(pAppId, self)
  local mobSession = commonNavigation.getMobileSession(pAppId, self)
  local hmiAppId = commonNavigation.getHMIAppId(pAppId)
  local cid = mobSession:SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = hmiAppId, unexpectedDisconnect = false })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ @subscribeWayPoints: SubscribeWayPoints successful sequence
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function commonNavigation.subscribeWayPoints(pAppId, self)
  self, pAppId = commonNavigation.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobSession = commonNavigation.getMobileSession(pAppId, self)
  local cid = mobSession:SendRPC("SubscribeWayPoints", {})
  if pAppId == 1 then
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    :Do(function(_, data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
  mobSession:ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  mobSession:ExpectNotification("OnHashChange")
  :Do(function(_, data)
      self.currentHashID = data.payload.hashID
    end)
end

--[[ @unsubscribeWayPoints: UnsubscribeWayPoints successful sequence
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function commonNavigation.unsubscribeWayPoints(pAppId, self)
  self, pAppId = commonNavigation.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobSession = commonNavigation.getMobileSession(pAppId, self)
  local cid = mobSession:SendRPC("UnsubscribeWayPoints", {})
  if pAppId == 1 then
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
    :Do(function(_, data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
  mobSession:ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  mobSession:ExpectNotification("OnHashChange")
  :Do(function(_, data)
      self.currentHashID = data.payload.hashID
    end)
end

--[[ @IGNITION_OFF: IGNITION_OFF sequence
--! @parameters:
--! self - test object
--]]
function commonNavigation.IGNITION_OFF(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
        { reason = "IGNITION_OFF" })
      self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered",
        { reason = "IGNITION_OFF" })
      SDL:DeleteFile()
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
      EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
    end)
end

--[[ @isSubscribed: OnWayPointChange successful sequence (subscribed)
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function commonNavigation.isSubscribed(pAppId, self)
  self, pAppId = commonNavigation.getSelfAndParams(pAppId, self)
  local mobSession = commonNavigation.getMobileSession(pAppId, self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  mobSession:ExpectNotification("OnWayPointChange", notification)
end

--[[ @isSubscribed: OnWayPointChange successful sequence (unsubscribed)
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function commonNavigation.isUnsubscribed(pAppId, self)
  self, pAppId = commonNavigation.getSelfAndParams(pAppId, self)
  local mobSession = commonNavigation.getMobileSession(pAppId, self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  mobSession:ExpectNotification("OnWayPointChange"):Times(0)
  commonTestCases:DelayedExp(commonNavigation.timeout)
end

--[[ @getMobileResultCodes: get all available result codes from Mobile API
--! @parameters: none
--! @return: table with result codes
--]]
local function getMobileResultCodes()
  local out = {}
  for k in pairs(mobile_api_schema.enum["Result"]) do
    table.insert(out, k)
  end
  return out
end

--[[ @getExpectedResultCodes: get expected result codes from Mobile API for particular RPC
--! @parameters:
--! pFunctionName - name of the RPC
--! @return: table with result codes
--]]
local function getExpectedResultCodes(pFunctionName)
  return mobile_api_schema.type["response"].functions[pFunctionName].param.resultCode.resultCodes
end

--[[ @getHMIResultCodes: get all available result codes from HMI API
--! @parameters: none
--! @return: table with result codes
--]]
local function getHMIResultCodes()
  local out = {}
  for k in pairs(hmi_api_schema.enum["Result"]) do
    table.insert(out, k)
  end
  return out
end

--[[ @isContain: verify if table contans particular value
--! @parameters:
--! pTbl - table
--! pValue - value
--! @return: true if value is in table, otherwise - false
--]]
local function isContain(pTbl, pValue)
  for _, v in pairs(pTbl) do
    if v == pValue then return true end
  end
  return false
end

--[[ @getSuccessResultCodes: get success result codes for particular RPC
--! @parameters:
--! pFunctionName - name of the RPC
--! @return: table with result codes
--]]
function commonNavigation.getSuccessResultCodes(pFunctionName)
  local out = {}
  for _, v in pairs(getExpectedResultCodes(pFunctionName)) do
    if isContain(successCodes, v) then table.insert(out, v) end
  end
  return out
end

--[[ @getFailureResultCodes: get failure result codes for particular RPC
--! @parameters:
--! pFunctionName - name of the RPC
--! @return: table with result codes
--]]
function commonNavigation.getFailureResultCodes(pFunctionName)
  local out = {}
  for _, v in pairs(getExpectedResultCodes(pFunctionName)) do
    if not isContain(successCodes, v) then table.insert(out, v) end
  end
  return out
end

--[[ @getUnexpectedResultCodes: get unexpected result codes for particular RPC
--! @parameters:
--! pFunctionName - name of the RPC
--! @return: table with result codes
--]]
function commonNavigation.getUnexpectedResultCodes(pFunctionName)
  local out = {}
  for _, v in pairs(getHMIResultCodes()) do
    if isContain(getMobileResultCodes(), v) then
      if not isContain(getExpectedResultCodes(pFunctionName), v) then table.insert(out, v) end
    end
  end
  return out
end

--[[ @getFilteredResultCodes: get filtered result codes for particular RPC
--! @parameters:
--! pFunctionName - name of the RPC
--! @return: table with result codes
--]]
function commonNavigation.getFilteredResultCodes()
  local out = {}
  for _, v in pairs(getHMIResultCodes()) do
    if not isContain(getMobileResultCodes(), v) then table.insert(out, v) end
  end
  return out
end

--[[ @printResultCodes: print result codes split by group
--! @parameters:
--! pResultCodes - table with all code groups
--]]
function commonNavigation.printResultCodes(pResultCodes)
  print("Success:")
  commonFunctions:printTable(pResultCodes.success)
  print("Failure:")
  commonFunctions:printTable(pResultCodes.failure)
  print("Unexpected:")
  commonFunctions:printTable(pResultCodes.unexpected)
  print("Filtered:")
  commonFunctions:printTable(pResultCodes.filtered)
end

return commonNavigation
