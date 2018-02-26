---------------------------------------------------------------------------------------------------
-- Navigation common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require('mobile_session')
local json = require('modules/json')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local events = require('events')
local test = require('user_modules/dummy_connecttest')
local expectations = require('expectations')
local Expectation = expectations.Expectation
local reporter = require('reporter')
local SDL = require('SDL')
local mq = require('mq')

local m = {}

--[[ Constants ]]
m.timeout = 2000
m.minTimeout = 500
m.appParams = {
  [1] = { appHMIType = "MEDIA", isMediaApplication = false },
  [2] = { appHMIType = "DEFAULT", isMediaApplication = true },
  [3] = { appHMIType = "DEFAULT", isMediaApplication = false },
  [4] = { appHMIType = "DEFAULT", isMediaApplication = false }
}
m.sdlMQ = "SDLMQ"
m.rpcSend = {}
m.rpcCheck = {}

for i = 1, 4 do
  config["application" .. i].registerAppInterfaceParams.appHMIType = { m.appParams[i].appHMIType }
  config["application" .. i].registerAppInterfaceParams.isMediaApplication = m.appParams[i].isMediaApplication
end

--[[ Variables ]]
local ptuTable = {}
local hmiAppIds = {}
local isMobileConnected = false
local grammarId = {}
local hashId = {}

--[[ Functions ]]
--[[ @execCMD: execute any linux command and return result
--! @parameters:
--! pCmd - command to execute
--! @return: result
--]]
local function execCMD(pCmd)
  local handle = io.popen(pCmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

--[[ @getDeviceName: provide device's name
--! @parameters: none
--! @return: device name
--]]
function m.getDeviceName()
  return config.mobileHost .. ":" .. config.mobilePort
end

--[[ @getDeviceMAC: provide device's MAC address
--! @parameters: none
--! @return: device MAC address
--]]
function m.getDeviceMAC()
  return execCMD("echo -n " .. m.getDeviceName() .. " | sha256sum | awk '{printf $1}'")
end

--[[ @cprint: print color message
--! @parameters:
--! pColor - color code
--! pMsg - message
--]]
function m.cprint(pColor, pMsg)
  print("\27[" .. tostring(pColor) .. "m" .. tostring(pMsg) .. "\27[0m")
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

local function getAppsCount()
  local count = 0
  for _ in pairs(hmiAppIds) do
    if test["mobileSession" .. count + 1] ~= nil then
      count = count + 1
    end
  end
  return count
end

--[[ @updatePTU: update PTU table with additional functional group for Navigation RPCs
--! @parameters:
--! pTbl - PTU table
--! pAppId - application number (1, 2, etc.)
--]]
function m.updatePTU(pTbl, pAppId)
  for i = 1, pAppId do
    pTbl.policy_table.app_policies[m.getAppPolicyId(i)] = {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      groups = { "Base-4", "Location-1" },
      AppHMIType = { m.appParams[i].appHMIType }
    }
  end
end

--[[ @ptu: perform policy table update
--! @parameters:
--! pPTUpdateFunc - additional function for update
--! pAppId - application number (1, 2, etc.)
--]]
local function ptu(pPTUpdateFunc, pAppId)
  if not pAppId then pAppId = 1 end
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptu_file_name = os.tmpname()
  local requestId = test.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      test.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name })
      getPTUFromPTS(ptuTable)

      m.updatePTU(ptuTable, pAppId)

      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end

      tableToJsonFile(ptuTable, ptu_file_name)

      local event = events.Event()
      event.matches = function(e1, e2) return e1 == e2 end
      EXPECT_EVENT(event, "PTU event")

      for id = 1, getAppsCount() do
        local mobileSession = m.getMobileSession(id)
        mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function()
            m.cprint(35, "App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            local corIdSystemRequest = mobileSession:SendRPC("SystemRequest",
              { requestType = "PROPRIETARY" }, ptu_file_name)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                test.hmiConnection:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                test.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
              end)
            mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptu_file_name) end)
          end)
        :Times(AtMost(1))
      end
    end)
end

--[[ @allowSDL: sequence that allows SDL functionality
--! @parameters: none
--]]
local function allowSDL()
  test.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = m.getDeviceMAC(),
      name = m.getDeviceName()
    }
  })
end

--[[ @registerStartSecureServiceFunc: register function to start secure service
--! @parameters:
--! pMobSession - mobile session
--]]
local function registerCustomExpFunctions(pMobSession)
  --[[ @ExpectAny: register expectation for any event on Mobile connection
  --! @parameters: none
  --]]
  function pMobSession:ExpectAny()
    local session = self.mobile_session_impl
    local event = events.Event()
    event.matches = function(_, data)
      return data.sessionId == session.sessionId.get()
    end
    local ret = Expectation("Any Mobile Event", session.connection)
    ret.event = event
    event_dispatcher:AddEvent(session.connection, event, ret)
    test:AddExpectation(ret)
    return ret
  end
end

--[[ @getAppPolicyId: return 'appId' from configuration file
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier from configuration file
--]]
function m.getAppPolicyId(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams.appID
end

--[[ @preconditions: precondition steps
--! @parameters: none
--]]
function m.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
end

--[[ @postconditions: postcondition steps
--! @parameters: none
--]]
function m.postconditions()
  StopSDL()
end

--[[ @activateApp: activate application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--]]
function m.activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = m.getHMIAppId(pAppId)
  local mobSession = m.getMobileSession(pAppId)
  local requestId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", systemContext = "MAIN" })
  commonTestCases:DelayedExp(m.minTimeout)
end

--[[ @deactivateApp: deactivate application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--]]
function m.deactivateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = m.getHMIAppId(pAppId)
  local mobSession = m.getMobileSession(pAppId)
  test.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", { appID = pHMIAppId })
  mobSession:ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED", systemContext = "MAIN" })
  commonTestCases:DelayedExp(m.minTimeout)
end

--[[ @getHMIAppId: get HMI application identifier
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier
--]]
function m.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[pAppId]
end

--[[ @getMobileSession: get mobile session
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: mobile session
--]]
function m.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  local session
  if not test["mobileSession" .. pAppId] then
    m.cprint(35, "Mobile session " .. pAppId .. " created")
    session = mobile_session.MobileSession(test, test.mobileConnection)
    test["mobileSession" .. pAppId] = session
    registerCustomExpFunctions(session)
    if config.defaultProtocolVersion > 2 then
      session.activateHeartbeat = true
      session.sendHeartbeatToSDL = true
      session.answerHeartbeatFromSDL = true
      session.ignoreSDLHeartBeatACK = true
    end
  else
    session = test["mobileSession" .. pAppId]
  end
  return session
end

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--]]
function m.registerApp(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
      test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[pAppId] = d1.params.application.appID
          test.hmiConnection:ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
          :Times(2)
          test.hmiConnection:ExpectRequest("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              test.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptuTable = jsonFileToTable(d2.params.file)
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

--[[ @policyTableUpdate: perform PTU
--! @parameters:
--! pPTUpdateFunc - function with additional updates
--! pExpNotificationFunc - function with specific expectations which needs to be done during PTU
--! pAppId - application number (1, 2, etc.)
--]]
function m.policyTableUpdate(pAppId, pPTUpdateFunc, pExpNotificationFunc)
  if not pAppId then pAppId = 1 end
  if not pExpNotificationFunc then
    test.hmiConnection:ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
    test.hmiConnection:ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  else
    pExpNotificationFunc()
  end
  ptu(pPTUpdateFunc, pAppId)
end

--[[ @start: starting sequence: starting of SDL, initialization of HMI, connect mobile
--! @parameters:
--! pHMIParams - table with parameters for HMI initialization
--]]
function m.start(pHMIParams)
  test:runSDL()
  commonFunctions:waitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          m.cprint(35, "HMI initialized")
          test:initHMI_onReady(pHMIParams)
          :Do(function()
              m.cprint(35, "HMI is ready")
              test:connectMobile()
              :Do(function()
                  isMobileConnected = true
                  m.cprint(35, "Mobile connected")
                  allowSDL(test)
                end)
            end)
        end)
    end)
end

--[[ @delayedExp: delay test step for specific timeout
--! @parameters: none
--]]
function m.delayedExp(pTimeOut)
  if not pTimeOut then pTimeOut = m.timeout end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(pTimeOut + 60000)
  RUN_AFTER(function() RAISE_EVENT(event, event) end, pTimeOut)
end

--[[ @ExpectAny: register expectation for any event on HMI connection
--! @parameters: none
--]]
function test.hmiConnection:ExpectAny()
  local event = events.Event()
  event.matches = function() return true end
  local ret = Expectation("Any HMI Event", self)
  ret.event = event
  event_dispatcher:AddEvent(self, event, ret)
  test:AddExpectation(ret)
  return ret
end

--[[ @ExpectRequest: register expectation for request on HMI connection
--! @parameters:
--! pName - name of the request
--! ... - expected data
--]]
function test.hmiConnection:ExpectRequest(pName, ...)
  local event = events.Event()
  event.matches = function(_, data) return data.method == pName end
  local args = table.pack(...)
  local ret = Expectation("HMI call " .. pName, self)
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

--[[ @ExpectResponse: register expectation for response on HMI connection
--! @parameters:
--! pName - name of the response
--! ... - expected data
--]]
function test.hmiConnection:ExpectResponse(pId, ...)
  local event = events.Event()
  event.matches = function(_, data) return data.id == pId end
  local args = table.pack(...)
  local ret = Expectation("HMI response " .. pId, self)
  if #args > 0 then
    ret:ValidIf(function(e, data)
        local arguments
        if e.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[e.occurences]
        end
        reporter.AddMessage("EXPECT_HMIRESPONSE",
          { ["Id"] = data.id, ["Type"] = "EXPECTED_RESULT" }, arguments)
        reporter.AddMessage("EXPECT_HMIRESPONSE",
          { ["Id"] = data.id, ["Type"] = "AVAILABLE_RESULT" }, data.params)
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
--]]
function test.hmiConnection:ExpectNotification(pName, ...)
  local event = events.Event()
  event.matches = function(_, data) return data.method == pName end
  local args = table.pack(...)
  local ret = Expectation("HMI notification " .. pName, self)
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

--[[ @getHMIConnection: return HMI connection object
--! @parameters: none
--! @return: HMI connection object
--]]
function m.getHMIConnection()
  return test.hmiConnection
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

--[[ @cleanSessions: delete all mobile sessions and close mobile connection
--! @parameters: none
--! @return: none
--]]
local function cleanSessions()
  if isMobileConnected == true then
    EXPECT_EVENT(events.disconnectedEvent, "Disconnected")
    :Do(function()
        isMobileConnected = false
        m.cprint(35, "Mobile disconnected")
      end)
  end
  local function toRun()
    for i = 1, getAppsCount() do
      test["mobileSession" .. i] = nil
      m.cprint(35, "Mobile session " .. i .. " deleted")
    end
    test.mobileConnection:Close()
  end
  RUN_AFTER(toRun, 1000)
  m.delayedExp()
end

--[[ @unexpectedDisconnect: perform unexpected disconnect sequence
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.unexpectedDisconnect(pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", {
    unexpectedDisconnect = true,
    appID = m.getHMIAppId(pAppId)
  })
  :Do(function()
      cleanSessions()
    end)
  m.getMobileSession(pAppId):Stop()
end

--[[ @ignitionOff: perform Ignition Off sequence
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
  local numOfSessions = getAppsCount()
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      SDL:DeleteFile()
      m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      for i = 1, numOfSessions do
        m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
        :Do(function()
            cleanSessions()
          end)
      end
    end)
  local numOfEvents = AtLeast(1)
  if numOfSessions == 0 then numOfEvents = 0 end
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(numOfEvents) -- due to SDL issue
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      SDL:StopSDL()
    end)
end

--[[ @unregisterApp: unregister application sequence
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.unregisterApp(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("UnregisterAppInterface", {})
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", {
    unexpectedDisconnect = false,
    appID = m.getHMIAppId(pAppId)
  })
end

--[[ @createMQ: create SDL MQ
--! @parameters: none
--! @return: none
--]]
function m.createMQ()
  local queue = mq.create("/" .. m.sdlMQ, "rw", "rw-rw----")
  if queue == nil then
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' can't be created")
    return
  else
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' created successfully")
  end
end

--[[ @sendMQSignal: send MQ signal
--! @parameters:
--! pSignal - signal
--! @return: none
--]]
function m.sendMQSignal(pSignal)
  local queue = mq.open("/" .. m.sdlMQ, "rw")
  if queue == nil then
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' can't be opened")
    return
  else
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' opened successfully")
  end
  local result = mq.send(queue, pSignal)
  if result == nil then
    m.cprint(35, "Signal '" .. pSignal .. "' was not sent")
    return
  else
    m.cprint(35, "Signal '" .. pSignal .. "' was sent successfully")
  end
  result = mq.close(queue)
  if result == nil then
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' can't be closed")
    return
  else
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' closed successfully")
  end
end

--[[ @deleteMQ: delete SDL MQ
--! @parameters: none
--! @return: none
--]]
function m.deleteMQ()
  local result = mq.unlink("/" .. m.sdlMQ)
  if result == nil then
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' can't be deleted")
    return
  else
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' deleted successfully")
  end
end

--[[ @receiveMQSignal: receive MQ signal
--! @parameters: none
--! @return: none
--]]
function m.receiveMQSignal()
  local queue = mq.open("/" .. m.sdlMQ, "rw")
  if queue == nil then
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' can't be opened")
    return
  else
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' opened successfully")
  end
  local msg = mq.receive(queue)
  if msg == nil then
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' can't be read")
    return
  else
    m.cprint(35, "Signal '" .. msg .. "' received successfully")
  end
  local result = mq.close(queue)
  if result == nil then
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' can't be closed")
    return
  else
    m.cprint(35, "Queue '" .. m.sdlMQ .. "' closed successfully")
  end
end

--[[ @connectMobile: connect mobile device
--! @parameters: none
--! @return: none
--]]
function m.connectMobile()
  test.mobileConnection:Connect()
  EXPECT_EVENT(events.connectedEvent, "Connected")
  :Do(function()
      m.cprint(35, "Mobile connected")
    end)
end

--[[ @reRegisterApp: re-register application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pHashId - array of application's hash ids
--! pCheckAppId - verification function for HMI Application id
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! pResultCode - expected result code
--! pDelay - delay
--! @return: none
--]]
function m.reRegisterApp(pAppId, pCheckAppId, pCheckResumptionData, pCheckResumptionHMILevel, pResultCode, pDelay)
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = config["application" .. pAppId].registerAppInterfaceParams
      params.hashID = hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
        application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName }
      })
      :Do(function()
          m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate")
          :Times(0)
          m.getHMIConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
          :Times(0)
        end)
      :ValidIf(function(_, data)
          return pCheckAppId(pAppId, data)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = pResultCode })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
  pCheckResumptionData(pAppId)
  pCheckResumptionHMILevel(pAppId)
  m.delayedExp(pDelay)
end

--[[ @sendMQLowVoltageSignal: send 'SDL_LOW_VOLTAGE' signal to SDL MQ
--! @parameters: none
--! @return: none
--]]
function m.sendMQLowVoltageSignal()
  m.sendMQSignal("SDL_LOW_VOLTAGE")
  cleanSessions()
end

--[[ @waitUntilSocketIsClosed: wait some time until SDL logger is closed
--! @parameters: none
--! @return: none
--]]
local function waitUntilSDLLoggerIsClosed()
  m.cprint(35, "Wait until SDL Logger is closed ...")
  local function getNetStat()
    local cmd = "netstat"
      .. " | grep -E '" .. config.sdl_logs_host .. ":" .. config.sdl_logs_port .. "\\s*FIN_WAIT'"
      .. " | wc -l"
    return tonumber(execCMD(cmd))
  end
  while getNetStat() > 0 do
    os.execute("sleep 1")
  end
  os.execute("sleep 1")
end

--[[ @sendMQShutDownSignal: send 'SHUT_DOWN' signal to SDL MQ
--! @parameters: none
--! @return: none
--]]
function m.sendMQShutDownSignal()
  SDL:DeleteFile()
  m.sendMQSignal("SHUT_DOWN")
  cleanSessions()
  local function toRun()
    SDL:StopSDL()
    waitUntilSDLLoggerIsClosed()
  end
  RUN_AFTER(toRun, 1000)
end

--[[ @sendMQWakeUpSignal: send 'WAKE_UP' signal to SDL MQ
--! @parameters: none
--! @return: none
--]]
function m.sendMQWakeUpSignal()
  m.sendMQSignal("WAKE_UP")
  m.delayedExp()
end

--[[ @waitUntilResumptionDataIsStored: wait some time until SDL saves resumption data
--! @parameters: none
--! @return: none
--]]
function m.waitUntilResumptionDataIsStored()
  m.cprint(35, "Wait ...")
  local fileName = commonPreconditions:GetPathToSDL()
    .. commonFunctions:read_parameter_from_smart_device_link_ini("AppInfoStorage")
  local function isFileExist()
    local f = io.open(fileName, "r")
    if f ~= nil then
      io.close(f)
      return true
    else
      return false
    end
  end
  while not isFileExist() do
    os.execute("sleep 1")
  end
end

--[[ @isSDLStopped: verifies if SDL stopped
--! @parameters: none
--! @return: none
--]]
function m.isSDLStopped()
  local s = SDL:CheckStatusSDL()
  if s ~= SDL.STOPPED then
    return test:FailTestCase("SDL is not stopped")
  end
  m.cprint(35, "SDL stopped")
end

m.rpcSend.AddCommand = function(pAppId, pCommandId)
    if not pCommandId then pCommandId = 1 end
    local cmd = "CMD" .. pCommandId
    local cid = m.getMobileSession(pAppId):SendRPC("AddCommand", { cmdID = pCommandId, vrCommands = { cmd }})
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        grammarId[pAppId] = data.params.grammarID
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[pAppId] = data.payload.hashID
      end)
  end
m.rpcSend.AddSubMenu = function(pAppId)
    local cid = m.getMobileSession(pAppId):SendRPC("AddSubMenu", { menuID = 1, position = 500, menuName = "SubMenu" })
    m.getHMIConnection():ExpectRequest("UI.AddSubMenu")
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[pAppId] = data.payload.hashID
      end)
  end
m.rpcSend.CreateInteractionChoiceSet = function(pAppId)
    local cid = m.getMobileSession(pAppId):SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = 1,
      choiceSet = {
        { choiceID = 1, menuName = "Choice", vrCommands = { "VrChoice" }}
      }
    })
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        grammarId[pAppId] = data.params.grammarID
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[pAppId] = data.payload.hashID
      end)
  end
m.rpcSend.NoRPC = function() end

m.rpcCheck.AddCommand = function(pAppId, pCommandId)
    if not pCommandId then pCommandId = 1 end
    local cmd = "CMD" .. pCommandId
    m.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = pCommandId,
      vrCommands = { cmd },
      type = "Command",
      grammarID = grammarId[pAppId],
      appID = m.getHMIAppId(pAppId)
    })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
m.rpcCheck.AddSubMenu = function(pAppId)
    m.getHMIConnection():ExpectRequest("UI.AddSubMenu", {
      menuID = 1,
      menuParams = {
        position = 500,
        menuName = "SubMenu"
      },
      appID = m.getHMIAppId(pAppId)
    })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
m.rpcCheck.CreateInteractionChoiceSet = function(pAppId)
  m.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = 1,
      vrCommands = { "VrChoice" },
      type = "Choice",
      grammarID = grammarId[pAppId],
      appID = m.getHMIAppId(pAppId)
    })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
m.rpcCheck.NoRPC = function() end

return protect(m)
