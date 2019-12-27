---------------------------------------------------------------------------------------------------
-- SendLocation common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local json = require("modules/json")

local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local events = require("events")

local api_loader = require("modules/api_loader")
local mobile_api = api_loader.init("data/MOBILE_API.xml")
local mobile_api_schema = mobile_api.interface[next(mobile_api.interface)]
local hmi_api = api_loader.init("data/HMI_API.xml")
local hmi_api_schema = hmi_api.interface["Common"]

--[[ Local Variables ]]
local ptu_table = {}
local hmiAppIds = {}

local commonSendLocation = {}

commonSendLocation.timeout = 2000
commonSendLocation.minTimeout = 500

local successCodes = {
  "SUCCESS",
  "WARNINGS",
  "WRONG_LANGUAGE",
  "RETRY",
  "SAVED"
}

local excludedCodes = {
  "UNSUPPORTED_RESOURCE" -- excluded due to unresolved clarification
}

local function getAvailableParams()
  local out = {}
  for k in pairs(mobile_api_schema.type["request"].functions["SendLocation"].param) do
    table.insert(out, k)
  end
  return out
end

local function allowSDL(self)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = commonSendLocation.getDeviceMAC(),
      name = commonSendLocation.getDeviceName()
    }
  })
end

local function checkIfPTSIsSentAsBinary(bin_data)
  if not (bin_data ~= nil and string.len(bin_data) > 0) then
    commonFunctions:userPrint(31, "PTS was not sent to Mobile in payload of OnSystemRequest")
  end
end

function commonSendLocation.getSendLocationConfig()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "SendLocation" }
  }
end

local function getPTUFromPTS(tbl)
  tbl.policy_table.consumer_friendly_messages.messages = nil
  tbl.policy_table.device_data = nil
  tbl.policy_table.module_meta = nil
  tbl.policy_table.usage_and_error_counts = nil
  tbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  tbl.policy_table.module_config.preloaded_pt = nil
  tbl.policy_table.module_config.preloaded_date = nil
end

local function jsonFileToTable(pFileName)
  local f = io.open(pFileName, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

local function ptu(self, id, pUpdateFunction)
  local function getAppsCount()
    local count = 0
    for _ in pairs(hmiAppIds) do
      count = count + 1
    end
    return count
  end

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
      local function updatePTU(tbl)
        tbl.policy_table.functional_groupings.SendLocation.rpcs.SendLocation.parameters = {}
        for _, v in pairs(getAvailableParams()) do
          table.insert(tbl.policy_table.functional_groupings.SendLocation.rpcs.SendLocation.parameters, v)
        end
        tbl.policy_table.app_policies[commonSendLocation.getMobileAppId(id)] = commonSendLocation.getSendLocationConfig()
      end
      updatePTU(ptu_table)
      if pUpdateFunction then
        pUpdateFunction(ptu_table)
      end
      local function tableToJsonFile(tbl, file_name)
        local f = io.open(file_name, "w")
        f:write(json.encode(tbl))
        f:close()
      end
      tableToJsonFile(ptu_table, ptu_file_name)

      local event = events.Event()
      event.matches = function(self, e) return self == e end
      EXPECT_EVENT(event, "PTU event")
      :Timeout(11000)

      for id = 1, getAppsCount() do
        local mobileSession = commonSendLocation.getMobileSession(id, self)
        mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_, d2)
            print("App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            checkIfPTSIsSentAsBinary(d2.binaryData)
            local corIdSystemRequest = mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                self.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                  { policyfile = policy_file_path .. "/" .. policy_file_name })
              end)
            mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptu_file_name) end)
          end)
        :Times(AtMost(1))
      end
    end)
end

function commonSendLocation.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

--[[Module functions]]

function commonSendLocation.activateApp(pAppId, self)
  self, pAppId = commonSendLocation.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
  local mobSession = commonSendLocation.getMobileSession(pAppId, self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  commonTestCases:DelayedExp(commonSendLocation.minTimeout)
end

function commonSendLocation.backupHMICapabilities()
  local hmiCapabilitiesFile = commonFunctions:read_parameter_from_smart_device_link_ini("HMICapabilities")
  commonPreconditions:BackupFile(hmiCapabilitiesFile)
end

function commonSendLocation.delayedExp(timeout)
  if not timeout then timeout = commonSendLocation.timeout end
  commonTestCases:DelayedExp(timeout)
end

function commonSendLocation.getDeviceName()
  return config.mobileHost .. ":" .. config.mobilePort
end

function commonSendLocation.getDeviceMAC()
  local cmd = "echo -n " .. commonSendLocation.getDeviceName() .. " | sha256sum | awk '{printf $1}'"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

function commonSendLocation.getSelfAndParams(...)
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

function commonSendLocation.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
end

function commonSendLocation.getMobileSession(pAppId, self)
  self, pAppId = commonSendLocation.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  return self["mobileSession" .. pAppId]
end

function commonSendLocation.getMobileAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams.appID
end

function commonSendLocation.getPathToSDL()
  return config.pathToSDL
end

function commonSendLocation.postconditions()
  StopSDL()
end

function commonSendLocation.putFile(pFileName, self)
  self, pFileName = commonSendLocation.getSelfAndParams(pFileName, self)
  local cid = self.mobileSession1:SendRPC(
    "PutFile",
    {syncFileName = pFileName, fileType = "GRAPHIC_PNG", persistentFile = false, systemFile = false},
    "files/icon.png")

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function commonSendLocation.registerApplicationWithPTU(pAppId, pUpdateFunction, self)
  self, pAppId, pUpdateFunction = commonSendLocation.getSelfAndParams(pAppId, pUpdateFunction, self)
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
            {status = "UPDATE_NEEDED"}, {status = "UPDATING"}, {status = "UP_TO_DATE" })
          :Times(3)
          EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptu_table = jsonFileToTable(d2.params.file)
              ptu(self, pAppId, pUpdateFunction)
            end)
        end)
      self["mobileSession" .. pAppId]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. pAppId]:ExpectNotification("OnHMIStatus",
            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
          :Times(1)
          self["mobileSession" .. pAppId]:ExpectNotification("OnPermissionsChange")
          :Times(AtLeast(1)) -- todo: issue with SDL --> notification is sent twice
        end)
    end)
end

function commonSendLocation.registerApplication(id, self)
  self, id = commonSendLocation.getSelfAndParams(id, self)
  if not id then id = 1 end
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface",
        config["application" .. id].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        {application = {appName = config["application" .. id].registerAppInterfaceParams.appName}})
      :Do(function(_, d1)
          hmiAppIds[config["application" .. id].registerAppInterfaceParams.appID] = d1.params.application.appID
        end)
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1)) -- issue with SDL --> notification is sent twice
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

function commonSendLocation.restoreHMICapabilities()
  local hmiCapabilitiesFile = commonFunctions:read_parameter_from_smart_device_link_ini("HMICapabilities")
  commonPreconditions:RestoreFile(hmiCapabilitiesFile)
end

function commonSendLocation.start(pHMIParams, self)
  self, pHMIParams = commonSendLocation.getSelfAndParams(pHMIParams, self)
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

function commonSendLocation.unregisterApp(pAppId, self)
  local mobSession = commonSendLocation.getMobileSession(pAppId, self)
  local hmiAppId = commonSendLocation.getHMIAppId(pAppId)
  local cid = mobSession:SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = hmiAppId, unexpectedDisconnect = false })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local function getMobileResultCodes()
  local out = {}
  for k in pairs(mobile_api_schema.enum["Result"]) do
    table.insert(out, k)
  end
  return out
end

local function getExpectedResultCodes(pFunctionName)
  return mobile_api_schema.type["response"].functions[pFunctionName].param.resultCode.resultCodes
end

local function getHMIResultCodes()
  local out = {}
  for k in pairs(hmi_api_schema.enum["Result"]) do
    table.insert(out, k)
  end
  return out
end

local function isContain(pTbl, pValue)
  for _, v in pairs(pTbl) do
    if v == pValue then return true end
  end
  return false
end

function commonSendLocation.getKeysFromItemsTable(pTbl, pKey)
  local out = {}
  for _, item in pairs(pTbl) do
    if not isContain(out, item[pKey]) then
      table.insert(out, item[pKey])
    end
  end
  return out
end

local function getResultCodesMap()
  local out = {}
  for _, v in pairs(getHMIResultCodes()) do
    if not isContain(excludedCodes, v) then
      if isContain(getMobileResultCodes(), v) then
        table.insert(out, { mobile = v, hmi = v })
      else
        table.insert(out, { mobile = nil, hmi = v })
      end
    end
  end
  return out
end

function commonSendLocation.getSuccessResultCodes(pFunctionName)
  local out = {}
  for _, item in pairs(getResultCodesMap()) do
    if isContain(getExpectedResultCodes(pFunctionName), item.mobile) and isContain(successCodes, item.mobile) then
      table.insert(out, { mobile = item.mobile, hmi = item.hmi })
    end
  end
  return out
end

function commonSendLocation.getFailureResultCodes(pFunctionName)
  local out = {}
  for _, item in pairs(getResultCodesMap()) do
    if isContain(getExpectedResultCodes(pFunctionName), item.mobile) and not isContain(successCodes, item.mobile) then
      table.insert(out, { mobile = item.mobile, hmi = item.hmi })
    end
  end
  return out
end

function commonSendLocation.getUnexpectedResultCodes(pFunctionName)
  local out = {}
  for _, item in pairs(getResultCodesMap()) do
    local success = false
    if isContain(successCodes, item.mobile) then success = true end
    if item.mobile ~= nil and not isContain(getExpectedResultCodes(pFunctionName), item.mobile) then
      table.insert(out, { mobile = item.mobile, hmi = item.hmi, success = success })
    end
  end
  return out
end

function commonSendLocation.getUnmappedResultCodes()
  local out = {}
  for _, item in pairs(getResultCodesMap()) do
    if item.mobile == nil then
      table.insert(out, { mobile = item.mobile, hmi = item.hmi })
    end
  end
  return out
end

function commonSendLocation.printResultCodes(pResultCodes)
  local function printItem(pItem)
    for _, v in pairs(pItem) do
      local msg = v.hmi
      if v.mobile and v.mobile ~= v.hmi then msg = msg .. "\t" .. v.mobile end
      print("", msg)
    end
  end
  print("Success:")
  printItem(pResultCodes.success)
  print("Failure:")
  printItem(pResultCodes.failure)
  print("Unexpected:")
  printItem(pResultCodes.unexpected)
  print("Unmapped:")
  printItem(pResultCodes.unmapped)
end

--[[ @filterTable: remove from 1st table items provided in 2nd table
--! @parameters:
--! pFilteredTbl - table which will be filtered
--! pValuesTbl - table with values that are going to be removed
--]]
function commonSendLocation.filterTable(pFilteredTbl, pValuesTbl)
  local i = 1
  while i <= #pFilteredTbl do
    if isContain(pValuesTbl, pFilteredTbl[i]) then
      table.remove(pFilteredTbl, i)
    else
      i = i + 1
    end
  end
end

return commonSendLocation
