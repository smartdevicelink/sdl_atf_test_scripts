---------------------------------------------------------------------------------------------------
-- Navigation common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 3

config.serverCertificatePath = "./files/Security/spt_credential.pem"
config.serverPrivateKeyPath = "./files/Security/spt_credential.pem"
config.serverCAChainCertPath = "./files/Security/spt_credential.pem"

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local json = require("modules/json")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local events = require("events")
local test = require("user_modules/dummy_connecttest")
local expectations = require('expectations')
local Expectation = expectations.Expectation
local constants = require('protocol_handler/ford_protocol_constants')
local reporter = require("reporter")

local m = {}

--[[ Constants ]]
m.timeout = 2000
m.minTimeout = 500
m.appId1 = 1
m.appId2 = 2
m.frameInfo = constants.FRAME_INFO

--[[ Variables ]]
local ptuTable = {}
local hmiAppIds = {}

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
function m.updatePTU(pTbl, pAppId)
  pTbl.policy_table.app_policies[m.getAppID(pAppId)] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "Location-1" }
  }
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

      local function getAppsCount()
        local count = 0
        for _ in pairs(hmiAppIds) do
          count = count + 1
        end
        return count
      end
      for id = 1, getAppsCount() do
        local mobileSession = m.getMobileSession(id)
        mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function()
            print("App ".. id .. " was used for PTU")
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
  test.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    { allowed = true, source = "GUI", device = { id = config.deviceMAC, name = "127.0.0.1" } })
end

--[[ @registerStartSecureServiceFunc: register function to start secure service
--! @parameters:
--! pMobSession - mobile session
--]]
local function registerStartSecureServiceFunc(pMobSession)
  function pMobSession.mobile_session_impl.control_services:StartSecureService(pServiceId)
    local msg = {
      serviceType = pServiceId,
      frameInfo = constants.FRAME_INFO.START_SERVICE,
      sessionId = self.session.sessionId.get(),
      encryption = true
    }
    self:Send(msg)
  end
  function pMobSession.mobile_session_impl:StartSecureService(pServiceId)
    if not self.isSecuredSession then
      self.security:registerSessionSecurity()
      self.security:prepareToHandshake()
    end
    return self.control_services:StartSecureService(pServiceId)
  end
end

--[[ @registerExpectServiceEventFunc: register functions for expectations of control messages:
--! Service Start ACK/NACK and Handshake
--! @parameters:
--! pMobSession - mobile session
--]]
local function registerExpectServiceEventFunc(pMobSession)
  function pMobSession:ExpectControlMessage(pServiceId, pData)
    local session = self.mobile_session_impl.control_services.session
    local event = events.Event()
    event.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
      data.serviceType == pServiceId and
      (pServiceId == constants.SERVICE_TYPE.RPC or data.sessionId == session.sessionId.get()) and
      (data.frameInfo == constants.FRAME_INFO.START_SERVICE_ACK or
        data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK)
    end
    local ret = session:ExpectEvent(event, "StartService")
    :Do(function(_, data)
        if data.encryption == true and data.frameInfo == constants.FRAME_INFO.START_SERVICE_ACK then
          session.security:registerSecureService(pServiceId)
        end
      end)
    :ValidIf(function(_, data)
        if data.encryption ~= pData.encryption then
          return false, "Expected 'encryption' flag is '" .. tostring(pData.encryption)
            .. "', actual is '" .. tostring(data.encryption) .. "'"
        end
        return true
      end)
    :ValidIf(function(_, data)
        if data.frameInfo ~= pData.frameInfo then
          return false, "Expected 'frameInfo' is '" .. tostring(pData.frameInfo)
            .. "', actual is '" .. tostring(data.frameInfo) .. "'"
        end
        return true
      end)
    return ret
  end

  function pMobSession:ExpectHandshakeMessage()
    local session = self.mobile_session_impl.control_services.session
    local event = events.Event()
    event.matches = function(e1, e2) return e1 == e2 end
    local ret = pMobSession:ExpectEvent(event, "Handshake")
    local handshakeEvent = events.Event()
    handshakeEvent.matches = function(_, data)
        return data.frameType ~= constants.FRAME_TYPE.CONTROL_FRAME
          and data.serviceType == constants.SERVICE_TYPE.CONTROL
          and data.sessionId == session.sessionId.get()
          and data.rpcType == constants.BINARY_RPC_TYPE.NOTIFICATION
          and data.rpcFunctionId == constants.BINARY_RPC_FUNCTION_ID.HANDSHAKE
      end
    session:ExpectEvent(handshakeEvent, "Handshake internal")
    :Do(function(_, data)
      local binData = data.binaryData
        local dataToSend = session.security:performHandshake(binData)
        if dataToSend then
          local handshakeMessage = {
            frameInfo = 0,
            serviceType = constants.SERVICE_TYPE.CONTROL,
            encryption = false,
            rpcType = constants.BINARY_RPC_TYPE.NOTIFICATION,
            rpcFunctionId = constants.BINARY_RPC_FUNCTION_ID.HANDSHAKE,
            rpcCorrelationId = data.rpcCorrelationId,
            binaryData = dataToSend
          }
          session:Send(handshakeMessage)
        end
      end)
    :Do(function()
        if session.security:isHandshakeFinished() then
          event_dispatcher:RaiseEvent(test.mobileConnection, event)
        end
      end)
    :Times(AnyNumber())
    return ret
  end
end

--[[ @getAppID: return 'appID' from configuration file
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier from configuration file
--]]
function m.getAppID(pAppId)
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
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
  local mobSession = m.getMobileSession(pAppId)
  local requestId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  commonTestCases:DelayedExp(m.minTimeout)
end

--[[ @getHMIAppId: get HMI application identifier
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier
--]]
function m.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
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
    session = mobile_session.MobileSession(test, test.mobileConnection)
    test["mobileSession" .. pAppId] = session
    registerStartSecureServiceFunc(session)
    registerExpectServiceEventFunc(session)
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
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID] = d1.params.application.appID
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

--[[ @registerAppWOPTU: register mobile application and do not perform PTU
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--]]
function m.registerAppWOPTU(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
      test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID] = d1.params.application.appID
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
function m.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc, pAppId)
  if not pAppId then pAppId = 1 end
  if not pExpNotificationFunc then
    test.hmiConnection:ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
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

--[[ @delayedExp: delay test step for specific timeout
--! @parameters: none
--]]
function m.delayedExp(pTimeOut)
  if not pTimeOut then pTimeOut = m.timeout end
  commonTestCases:DelayedExp(pTimeOut)
end

--[[ @readFile: read data from file
--! @parameters:
--! pPath - path to file
-- @return: content of the file
--]]
function m.readFile(pPath)
    local open = io.open
    local file = open(pPath, "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
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

--[[ @setForceProtectedServiceParam: set value of 'ForceProtectedService' parameter in SDL .ini file
--! @parameters:
--! pParamValue - value of the paramter
--]]
function m.setForceProtectedServiceParam(pParamValue)
  local paramName = "ForceProtectedService"
  commonFunctions:SetValuesInIniFile(paramName .. "%s-=%s-[%d,A-Z,a-z]-%s-\n", paramName, pParamValue)
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

--[[ @protect: start audio/video service
--! @parameters:
--! pService - service value
--! pAppId - app id value for session
--! @return: none
--]]
function m.startService(pService, pAppId)
  if not pAppId then pAppId = 1 end
  test["mobileSession" .. pAppId]:StartService(pService)
  if pService == 10 then
    EXPECT_HMICALL("Navigation.StartAudioStream")
    :Do(function(exp,data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  elseif pService == 11 then
    EXPECT_HMICALL("Navigation.StartStream")
    :Do(function(exp,data)
      test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  else
    commonFunctions:userPrint( 31, "Service for opening is not set")
  end
end

--[[ @protect: start audio/video streaming
--! @parameters:
--! pService - service value
--! pFile -file for streaming
--! pAppId - app id value for session
--! @return: none
--]]
function m.StartStreaming(pService, pFile, pAppId)
  if not pAppId then pAppId = 1 end
  test["mobileSession" .. pAppId]:StartStreaming(pService, pFile, 160*1024)
  if pService == 11 then
    EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", { available = true })
  else
     EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", { available = true })
  end
  commonFunctions:userPrint(33, "Streaming...")
  m.delayedExp(3000)
end

--[[ @protect: stop audio/video streaming
--! @parameters:
--! pService - service value
--! pFile -file for streaming
--! pAppId - app id value for session
--! @return: none
--]]
function m.StopStreaming(pService, pFile, pAppId)
  if not pAppId then pAppId = 1 end
  test["mobileSession" .. pAppId]:StopStreaming(pFile)
  if pService == 11 then
    EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", { available = false })
  else
     EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", { available = false })
  end
end

--[[ @protect: Rejecting audio/video service start
--! @parameters:
--! pService - service value
--! pAppId - app id value for session
--! @return: none
--]]
function m.RejectingServiceStart(pService, pAppId)
  if not pAppId then pAppId = 1 end
  local serviceType
  if 11 == pService then
    serviceType = constants.SERVICE_TYPE.VIDEO
  elseif 10 == pService then
    serviceType = constants.SERVICE_TYPE.PCM
  end
  local StartServiceResponseEvent = events.Event()
  StartServiceResponseEvent.matches =
  function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
    data.serviceType == serviceType and
    data.sessionId == test["mobileSession" .. pAppId].sessionId and
    (data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK or
      data.frameInfo == constants.FRAME_INFO.START_SERVICE_ACK)
  end
  test["mobileSession" .. pAppId]:Send({
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      serviceType = serviceType,
      frameInfo = constants.FRAME_INFO.START_SERVICE
    })
  -- Expect StartServiceNACK on mobile app from SDL, it means service is not started
  test["mobileSession" .. pAppId]:ExpectEvent(StartServiceResponseEvent, "Expect StartServiceNACK")
  :ValidIf(function(_, data)
      if data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK then
        return true
      else
        return false, "StartService ACK received"
      end
    end)
end

return protect(m)
