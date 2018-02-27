---------------------------------------------------------------------------------------------------
-- Common actions module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local json = require("modules/json")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local events = require("events")
local test = require("user_modules/dummy_connecttest")
local expectations = require('expectations')
local reporter = require("reporter")
local utils = require("user_modules/utils")

--[[ Module ]]
local m = {}

--[[ Constants ]]
m.minTimeout = 500

--[[ Variables ]]
local ptuTable = {}
local hmiAppIds = {}
local originalValuesInSDLIni = {}

test.mobileSession = {}

--[[ Functions ]]

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

--[[ @getAppDataForPTU: provide application data for PTU
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.getAppDataForPTU(pAppId)
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "Location-1" },
    AppHMIType = m.getConfigAppParams(pAppId).appHMIType
  }
end

--[[ @updatePTU: update PTU table with application data
--! @parameters:
--! pTbl - PTU table
--! @return: none
--]]
function m.updatePTU(pTbl)
  for i = 1, m.getAppsCount() do
    pTbl.policy_table.app_policies[m.getConfigAppParams(i).appID] = m.getAppDataForPTU(i)
  end
end

--[[ @ptu: perform policy table update
--! @parameters:
--! pPTUpdateFunc - additional function for update
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
local function ptu(pPTUpdateFunc)
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptu_file_name = os.tmpname()
  local requestId = test.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  test.hmiConnection:ExpectResponse(requestId)
  :Do(function()
      test.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name })
      getPTUFromPTS(ptuTable)

      m.updatePTU(ptuTable)

      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end

      utils.tableToJsonFile(ptuTable, ptu_file_name)

      local event = events.Event()
      event.matches = function(e1, e2) return e1 == e2 end
      EXPECT_EVENT(event, "PTU event")
      for id = 1, m.getAppsCount() do
        local session = m.getMobileSession(id)
        session:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function()
            print("App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            local corIdSystemRequest = session:SendRPC("SystemRequest",
              { requestType = "PROPRIETARY" }, ptu_file_name)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                test.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                test.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
              end)
            session:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptu_file_name) end)
          end)
        :Times(AtMost(1))
      end
    end)
end

--[[ @allowSDL: allow SDL functionality for default device
--! @parameters: none
--! @return: none
--]]
local function allowSDL(self)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
end

--[[ @getConfigAppParams: return app's configuration from defined in config file
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier from configuration file
--]]
function m.getConfigAppParams(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams
end

--[[ @preconditions: precondition steps
--! @parameters: none
--! @return: none
--]]
function m.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

--[[ @activateApp: activate application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local requestId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  test.hmiConnection:ExpectResponse(requestId)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  utils.wait()
end

--[[ @getHMIAppId: get HMI application identifier
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier
--]]
function m.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[m.getConfigAppParams(pAppId).appID]
end

--[[ @getMobileSession: get mobile session
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: mobile session object
--]]
function m.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  local session
  if not test.mobileSession[pAppId] then
    session = mobileSession.MobileSession(test, test.mobileConnection)
    test.mobileSession[pAppId] = session
    if config.defaultProtocolVersion > 2 then
      session.activateHeartbeat = true
      session.sendHeartbeatToSDL = true
      session.answerHeartbeatFromSDL = true
      session.ignoreSDLHeartBeatACK = true
    end
  else
    session = test.mobileSession[pAppId]
  end
  return session
end

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.registerApp(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
      test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
          hmiAppIds[m.getConfigAppParams(pAppId).appID] = d1.params.application.appID
          test.hmiConnection:ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
          :Times(2)
          test.hmiConnection:ExpectRequest("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              test.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptuTable = utils.jsonFileToTable(d2.params.file)
            end)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ @registerAppWOPTU: register mobile application and do not perform PTU
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.registerAppWOPTU(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
      test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
          hmiAppIds[m.getConfigAppParams(pAppId).appID] = d1.params.application.appID
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ @policyTableUpdate: perform PTU
--! @parameters:
--! pPTUpdateFunc - function with additional updates
--! @return: none
--]]
function m.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  if pExpNotificationFunc then
    pExpNotificationFunc()
  else
    test.hmiConnection:ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
    test.hmiConnection:ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  end
  ptu(pPTUpdateFunc)
end

--[[ @start: starting sequence: starting of SDL, initialization of HMI, connect mobile
--! @parameters:
--! pHMIParams - table with parameters for HMI initialization
--! @return: none
--]]
function m.start(pHMIParams)
  test:runSDL()
  commonFunctions:waitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          test:initHMI_onReady(pHMIParams)
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              test:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                  allowSDL(test)
                end)
            end)
        end)
    end)
end

--[[ @ExpectRequest: register expectation for request on HMI connection
--! @parameters:
--! pName - name of the request
--! ... - expected data
--! @return: Expectation object
--]]
function test.hmiConnection:ExpectRequest(pName, ...)
  local event = events.Event()
  event.matches = function(_, data) return data.method == pName end
  local args = table.pack(...)
  local ret = expectations.Expectation("HMI call " .. pName, self)
  if #args > 0 then
    ret:ValidIf(function(e, data)
        local arguments
        if e.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[e.occurences]
        end
        reporter.AddMessage("EXPECT_HMICALL",
          { ["Id"] = data.id, ["name"] = tostring(pName),["Type"] = "EXPECTED_RESULT" }, arguments)
        reporter.AddMessage("EXPECT_HMICALL",
          { ["Id"] = data.id, ["name"] = tostring(pName),["Type"] = "AVAILABLE_RESULT" }, data.params)
        return compareValues(arguments, data.params, "params")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(self, event, ret)
  test:AddExpectation(ret)
  return ret
end

--[[ @ExpectNotification: register expectation for notification on HMI connection
--! @parameters:
--! pName - name of the notification
--! ... - expected data
--! @return: Expectation object
--]]
function test.hmiConnection:ExpectNotification(pName, ...)
  local event = events.Event()
  event.matches = function(_, data) return data.method == pName end
  local args = table.pack(...)
  local ret = expectations.Expectation("HMI notification " .. pName, self)
  if #args > 0 then
    ret:ValidIf(function(e, data)
        local arguments
        if e.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[e.occurences]
        end
        local cid = test.notification_counter
        test.notification_counter = test.notification_counter + 1
        reporter.AddMessage("EXPECT_HMINOTIFICATION",
          { ["Id"] = cid, ["name"] = tostring(pName), ["Type"] = "EXPECTED_RESULT" }, arguments)
        reporter.AddMessage("EXPECT_HMINOTIFICATION",
          { ["Id"] = cid, ["name"] = tostring(pName), ["Type"] = "AVAILABLE_RESULT" }, data.params)
        return compareValues(arguments, data.params, "params")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(self, event, ret)
  test:AddExpectation(ret)
  return ret
end

--[[ @ExpectResponse: register expectation for notification on HMI connection
--! @parameters:
--! pName - name of the notification
--! ... - expected data
--! @return: Expectation object
--]]
function test.hmiConnection:ExpectResponse(pId, ...)
  local event = events.Event()
  event.matches = function(_, data) return data.id == pId end
  local args = table.pack(...)
  local ret = expectations.Expectation("HMI response " .. pId, self)
  if #args > 0 then
    ret:ValidIf(function(e, data)
        local arguments
        if e.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[e.occurences]
        end
        reporter.AddMessage("EXPECT_HMIRESPONSE", { ["Id"] = data.id, ["Type"] = "EXPECTED_RESULT" }, arguments)
        reporter.AddMessage("EXPECT_HMIRESPONSE", { ["Id"] = data.id, ["Type"] = "AVAILABLE_RESULT" }, data.result)
        return compareValues(arguments, data.result, "result")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(self, event, ret)
  test:AddExpectation(ret)
  return ret
end

--[[ @getMobileConnection: return Mobile connection object
--! @parameters: none
--! @return: Mobile connection object
--]]
function m.getMobileConnection()
  return test.mobileConnection
end

--[[ @getHMIConnection: return HMI connection object
--! @parameters: none
--! @return: HMI connection object
--]]
function m.getHMIConnection()
  return test.hmiConnection
end

--[[ @setSDLConfigParameter: change original value of parameter in SDL .ini file
--! @parameters:
--! pParamName - name of the parameter
--! pParamValue - value to be set
--! @return: none
--]]
function m.setSDLIniParameter(pParamName, pParamValue)
  originalValuesInSDLIni[pParamName] = commonFunctions:read_parameter_from_smart_device_link_ini(pParamName)
  commonFunctions:write_parameter_to_smart_device_link_ini(pParamName, pParamValue)
end

--[[ @restoreSDLConfigParameters: restore original values of parameters in SDL .ini file
--! @parameters: none
--! @return: none
--]]
local function restoreSDLIniParameters()
  for pParamName, pParamValue in pairs(originalValuesInSDLIni) do
    commonFunctions:write_parameter_to_smart_device_link_ini(pParamName, pParamValue)
  end
end

--[[ @postconditions: postcondition steps
--! @parameters: none
--! @return: none
--]]
function m.postconditions()
  StopSDL()
  restoreSDLIniParameters()
end

function m.getAppsCount()
  return #test.mobileSession
end

return m
