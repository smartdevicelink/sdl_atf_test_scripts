---------------------------------------------------------------------------------------------------
-- System common module
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
local common = {}

--[[ Constants ]]
common.timeout = 2000
common.minTimeout = 500

--[[ Variables ]]
local ptu_table = {}
local hmiAppIds = {}

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
  pTbl.policy_table.vehicle_data = nil
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

--[[ @ptu: perform policy table update
--! @parameters:
--! pPTUpdateFunc - additional function for update
--! self - test object
--]]
local function ptu(pPTUpdateFunc, self)
  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name })
      getPTUFromPTS(ptu_table)

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
        local mobileSession = common.getMobileSession(id, self)
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
function common.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

--[[ @activateApp: activate application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--]]
function common.activateApp(pAppId, self)
  self, pAppId = common.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID]
  local mobSession = common.getMobileSession(pAppId, self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  commonTestCases:DelayedExp(common.minTimeout)
end

--[[ @getSelfAndParams: shifting parameters in order to move self at 1st position
--! @parameters:
--! ... - various parameters and self
--! @return: self and other parameters
--]]
function common.getSelfAndParams(...)
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

--[[ @getMobileSession: get mobile session
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! self - test object
--! @return: mobile session
--]]
function common.getMobileSession(pAppId, self)
  if not pAppId then pAppId = 1 end
  return self["mobileSession" .. pAppId]
end

--[[ @postconditions: postcondition steps
--! @parameters: none
--]]
function common.postconditions()
  StopSDL()
end

--[[ @registerAppWithPTU: register mobile application and perform PTU
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pPTUpdateFunc - additional function for update
--! self - test object
--]]
function common.registerAppWithPTU(pAppId, pPTUpdateFunc, self)
  self, pAppId, pPTUpdateFunc = common.getSelfAndParams(pAppId, pPTUpdateFunc, self)
  if not pAppId then pAppId = 1 end
  self["mobileSession" .. pAppId] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. pAppId]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. pAppId]:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID] = d1.params.application.appID
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
            { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
          :Times(3)
          EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptu_table = jsonFileToTable(d2.params.file)
              ptu(pPTUpdateFunc, self)
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
function common.start(pHMIParams, self)
  self, pHMIParams = common.getSelfAndParams(pHMIParams, self)
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

function common.convertTableToString(tbl, i)
  local strIndex = ""
  local strReturn = ""
  for j = 1, i do
    strIndex = strIndex .. "\t"
  end
  local strIndex2 = strIndex .."\t"
  local x = 0
  if type(tbl) == "table" then
    strReturn = strReturn .. strIndex .. "{\n"
    for k,v in pairs(tbl) do
      x = x + 1
      if type(k) == "number" then
        if type(v) == "table" then
          if x ~=1 then
            strReturn = strReturn .. ",\n"
          end
        else
          if x ==1 then
            strReturn = strReturn .. strIndex2
          else
            strReturn = strReturn .. ",\n" .. strIndex2
          end
        end
      else
        if x ==1 then
          strReturn = strReturn .. strIndex2 .. k .. " = "
        else
          strReturn = strReturn .. ",\n" .. strIndex2 .. k .. " = "
        end
        if type(v) == "table" then
          strReturn = strReturn .. "\n"
        end
      end
      strReturn = strReturn .. common.convertTableToString(v, i+1)
    end
    strReturn = strReturn .. "\n"
    strReturn = strReturn .. strIndex .. "}"
  else
    if type(tbl) == "number" then
      strReturn = strReturn .. tbl
    elseif type(tbl) == "boolean" then
      strReturn = strReturn .. tostring(tbl)
    elseif type(tbl) == "string" then
      strReturn = strReturn .. tbl
    end
  end
  return strReturn
end
--[[ @protect: make table immutable
--! @parameters:
--! pTbl - mutable table
--! @return: immutable table
--]]
local function protect(pTbl)
  local mt = {
    __index = pTbl,
    __newindex = function(_, k, v)
      error("Attempting to change item " .. tostring(k) .. " to " .. tostring(v), 2)
    end
  }
  return setmetatable({}, mt)
end

return protect(common)
