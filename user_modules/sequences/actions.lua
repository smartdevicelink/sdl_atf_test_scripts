---------------------------------------------------------------------------------------------------
-- Common actions module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local mobile = require("mobile_connection")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local events = require("events")
local test = require("user_modules/dummy_connecttest")
local expectations = require('expectations')
local reporter = require("reporter")
local utils = require("user_modules/utils")
local SDL = require('SDL')

--[[ Module ]]
local m = {
  init = {},
  mobile = {},
  hmi = {},
  ptu = {},
  app = {},
  run = {},
  sdl = {},
  json = utils.json
}

--[[ Constants ]]
m.minTimeout = 500
m.timeout = 2000

--[[ Variables ]]
local hmiAppIds = {}

test.mobileConnections = {}
test.mobileSession = {}

--[[ Functions ]]

--- Retrieve mobile connection from mobile session
local function getMobConnectionFromSession(pMobSession)
  return pMobSession.mobile_session_impl.connection
end

local function getPolicyAppId(pAppId)
  local appParams = m.app.getParams(pAppId)
  local appId = appParams.fullAppID
  if not appId then appId = appParams.appID end
  return appId
end

--- Get HMI key for App by script's App id
local function getHmiAppIdKey(pAppId)
  local appId = getPolicyAppId(pAppId)

  local connection = getMobConnectionFromSession(m.mobile.getSession(pAppId))
  return utils.getDeviceName(connection.host, connection.port) .. tostring(appId)
end

--- Raise event on mobile connection
local function MobRaiseEvent(self, pEvent, pEventName)
  if pEventName == nil then pEventName = "noname" end
  reporter.AddMessage(debug.getinfo(1, "n").name, pEventName)
  event_dispatcher:RaiseEvent(self, pEvent)
end

--- Create expectation for event on mobile connection
local function MobExpectEvent(self, pEvent, pEventName)
  if pEventName == nil then pEventName = "noname" end
  local ret = expectations.Expectation(pEventName, self)
  ret.event = pEvent
  event_dispatcher:AddEvent(self, pEvent, ret)
  test:AddExpectation(ret)
  return ret
end

--- Function to handle default mobile connection (backward compatibility)
-- Should be removed after scripts stop use test.mobileConnection
local function prepareMobileConnectionsTable()
  if test.mobileConnection then
    if test.mobileConnection.connection then
      local defaultMobileConnection = test.mobileConnection
      defaultMobileConnection.RaiseEvent = MobRaiseEvent
      defaultMobileConnection.ExpectEvent = MobExpectEvent
      test.mobileConnections[1] = defaultMobileConnection
    end
  end
end

prepareMobileConnectionsTable()

--- Provide default configuration for mobile session creation
local function getDefaultMobSessionConfig()
  local mobSesionConfig = {
    activateHeartbeat = false,
    sendHeartbeatToSDL = false,
    answerHeartbeatFromSDL = false,
    ignoreSDLHeartBeatACK = false
  }

  if config.defaultProtocolVersion > 2 then
    mobSesionConfig.activateHeartbeat = true
    mobSesionConfig.sendHeartbeatToSDL = true
    mobSesionConfig.answerHeartbeatFromSDL = true
    mobSesionConfig.ignoreSDLHeartBeatACK = true
  end
  return mobSesionConfig
end

--[[ @getPTUFromPTS: create policy table update table (PTU) using PTS
--! @parameters: none
--! @return: PTU table
--]]
local function getPTUFromPTS()
  local pTbl = {}
  local ptsFileName = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  if utils.isFileExist(ptsFileName) then
    pTbl = utils.jsonFileToTable(ptsFileName)
  else
    utils.cprint(35, "PTS file was not found, PreloadedPT is used instead")
    local appConfigFolder = commonFunctions:read_parameter_from_smart_device_link_ini("AppConfigFolder")
    if appConfigFolder == nil or appConfigFolder == "" then
      appConfigFolder = commonPreconditions:GetPathToSDL()
    end
    local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
    local ptsFile = appConfigFolder .. preloadedPT
    if utils.isFileExist(ptsFile) then
      pTbl = utils.jsonFileToTable(ptsFile)
    else
      utils.cprint(35, "PreloadedPT was not found, PTS is not created")
    end
  end
  if next(pTbl) ~= nil then
    pTbl.policy_table.consumer_friendly_messages = nil
    pTbl.policy_table.device_data = nil
    pTbl.policy_table.module_meta = nil
    pTbl.policy_table.usage_and_error_counts = nil
    pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
    pTbl.policy_table.module_config.preloaded_pt = nil
    pTbl.policy_table.module_config.preloaded_date = nil
  end
  return pTbl
end

--[[ Functions of run submodule ]]

--[[ @run.createEvent: create event
--! @parameters: none
--! @return: created event object
--]]
function m.run.createEvent()
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  return event
end

--[[ @run.runAfter: delayed function call
--! @parameters:
--! pFunc - function to call
--! pTimeOut - delay value
--! @return: none
--]]
function m.run.runAfter(pFunc, pTimeOut)
  RUN_AFTER(pFunc, pTimeOut)
end

--[[ @run.wait: delay test step for specified timeout
--! @parameters:
--! pTimeOut - time to wait in ms
--! @return: Expectation object which will be raised after specified timout
--]]
function m.run.wait(pTimeOut)
  if not pTimeOut then pTimeOut = m.timeout end
  local event = m.run.createEvent()
  local ret = m.hmi.getConnection():ExpectEvent(event, "Delayed event"):Timeout(pTimeOut + 60000)
  m.run.runAfter(function() m.hmi.getConnection():RaiseEvent(event, "Delayed event") end, pTimeOut)
  return ret
end

--[[ @run.fail: fail test step
--! @parameters:
--! pCause - message with reason of the fail
--! @return: none
--]]
function m.run.fail(pCause)
  test:FailTestCase(pCause)
end

--[[ Functions of init submodule ]]

--[[ @init.SDL: start SDL
--! @parameters: none
--! @return: Expectation object of SDL start
--]]
function m.init.SDL()
  local ret = m.sdl.start()
  ret:Do(function()
      utils.cprint(35, "SDL started")
    end)
  return ret
end

--[[ @init.HMI: start HMI
--! @parameters: none
--! @return: Expectation object of HMI start
--]]
function m.init.HMI()
  local ret = test:initHMI()
  ret:Do(function()
      utils.cprint(35, "HMI initialized")
    end)
  return ret
end

--[[ @init.HMI_onReady: init HMI
--! @parameters:
--! pHMIParams - parameters with HMI capabilities
--! @return: Expectation object of HMI readiness
--]]
function m.init.HMI_onReady(pHMIParams)
  local ret = test:initHMI_onReady(pHMIParams)
  ret:Do(function()
      utils.cprint(35, "HMI is ready")
    end)
  return ret
end

--[[ @init.HMI: connect default mobile connection
--! @parameters: none
--! @return: Expectation object of connection
--]]
function m.init.connectMobile()
  return m.mobile.connect()
end

--[[ @init.allowSDL: allow default mobile device to use SDL
--! @parameters: none
--! @return: Expectation object of allowance
--]]
function m.init.allowSDL()
  local ret = m.mobile.allowSDL()
  ret:Do(function()
      utils.cprint(35, "SDL allowed")
    end)
  return ret
end

--[[ Functions of hmi submodule ]]

--[[ @hmi.getConnection: Get HMI connection
--! @parameters: none
--! @return: Hmi connection object
--]]
function m.hmi.getConnection()
  return test.hmiConnection
end

--[[ Functions of mobile submodule ]]

--[[ @mobile.createConnection: Create mobile connection
--! @parameters:
--! pMobConnId - script's mobile connection id
--! pMobConnHost - mobile connection host
--! pMobConnPort - mobile connection port
--! @return: none
--]]
function m.mobile.createConnection(pMobConnId, pMobConnHost, pMobConnPort)
  if pMobConnId == nil then pMobConnId = 1 end
  local filename = "mobile" .. pMobConnId .. ".out"
  local tcpConnection = tcp.Connection(pMobConnHost, pMobConnPort)
  local fileConnection = file_connection.FileConnection(filename, tcpConnection)
  local connection = mobile.MobileConnection(fileConnection)
  connection.RaiseEvent = MobRaiseEvent
  connection.ExpectEvent = MobExpectEvent
  connection.host = pMobConnHost
  connection.port = pMobConnPort
  event_dispatcher:AddConnection(connection)
  test.mobileConnections[pMobConnId] = connection
end

--[[ @mobile.connect: Connect mobile connection
--! @parameters:
--! pMobConnId - script's mobile connection id
--! @return: Expectation object of connection
--]]
function m.mobile.connect(pMobConnId)
  if pMobConnId == nil then pMobConnId = 1 end
  local connection = m.mobile.getConnection(pMobConnId)

  connection:ExpectEvent(events.disconnectedEvent, "Disconnected")
  :Pin()
  :Times(AnyNumber())
  :Do(function()
      utils.cprint(35, "Mobile #" .. pMobConnId .. " disconnected")
    end)

  local ret = connection:ExpectEvent(events.connectedEvent, "Connected")
  ret:Do(function()
    utils.cprint(35, "Mobile #" .. pMobConnId .. " connected")
  end)
  connection:Connect()
  return ret
end

--[[ @mobile.disconnect: Disconnect mobile connection
--! @parameters:
--! pMobConnId - script's mobile connection id
--! @return: Expectation object of disconnection
--]]
function m.mobile.disconnect(pMobConnId)
  if pMobConnId == nil then pMobConnId = 1 end
  local connection = m.mobile.getConnection(pMobConnId)
  local sessions = m.mobile.getApps(pMobConnId)
  for id in pairs(sessions) do
    m.mobile.deleteSession(id)
  end
  -- remove pinned mobile disconnect expectation
  connection:Close()
end

--[[ @mobile.deleteConnection: Remove mobile connection
--! @parameters:
--! pMobConnId - script's mobile connection id
--! @return: none
--]]
function m.mobile.deleteConnection(pMobConnId)
  if pMobConnId == nil then pMobConnId = 1 end
  local connection = m.mobile.getConnection(pMobConnId)
  event_dispatcher:DeleteConnection(connection)
  test.mobileConnections[pMobConnId] = nil
end

--[[ @mobile.getConnection: Get mobile connection
--! @parameters:
--! pMobConnId - script's mobile connection id
--! @return: mobile connection object
--]]
function m.mobile.getConnection(pMobConnId)
  if pMobConnId == nil then pMobConnId = 1 end
  return test.mobileConnections[pMobConnId]
end

--[[ @mobile.allowSDL: allow mobile connection to use SDL
--! @parameters:
--! pMobConnId - script's mobile connection id
--! @return: mobile connection object
--]]
function m.mobile.allowSDL(pMobConnId)
  if pMobConnId == nil then pMobConnId = 1 end
  local connection = m.mobile.getConnection(pMobConnId)
  local event = m.run.createEvent()
  m.hmi.getConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(connection.host, connection.port),
      name = utils.getDeviceName(connection.host, connection.port)
    }
  })
  m.run.runAfter(function() m.hmi.getConnection():RaiseEvent(event, "Allow SDL event") end, m.minTimeout)
  return m.hmi.getConnection():ExpectEvent(event, "Allow SDL event")
end

--[[ @mobile.getSession: retrieve mobile session
--! @parameters:
--! pAppId - script's mobile session id
--! @return: mobile session object
--]]
function m.mobile.getSession(pAppId)
  if pAppId == nil then pAppId = 1 end
  return test.mobileSession[pAppId]
end

--[[ @mobile.createSession: create mobile session on mobile connectuion
--! @parameters:
--! pAppId - script's mobile application id
--! pMobConnId - script's mobile connection id
--! pMobSesionConfig - mobile session configuration
--! @return: mobile session object
--]]
function m.mobile.createSession(pAppId, pMobConnId, pMobSesionConfig)
  if pAppId == nil then pAppId = 1 end
  if pMobConnId == nil then pMobConnId = 1 end
  if pMobSesionConfig == nil then pMobSesionConfig = getDefaultMobSessionConfig() end

  local session = mobileSession.MobileSession(test, test.mobileConnections[pMobConnId])
  for k, v in pairs(pMobSesionConfig) do
    session[k] = v
  end

  test.mobileSession[pAppId] = session
  return session
end

--[[ @mobile.deleteSession: remove mobile session
--! @parameters:
--! pAppId - script's mobile application id
--! @return: mobile session object
--]]
function m.mobile.deleteSession(pAppId)
  if pAppId == nil then pAppId = 1 end
  m.mobile.getSession(pAppId):Stop()
  :Do(function()
      test.mobileSession[pAppId] = nil
    end)
end

--[[ @mobile.getApps: get collection of mobile sessions on mobile connectuion
--! @parameters:
--! pMobConnId - script's mobile connection id (nil - means all mobile connections)
--! @return: mobile session collection
--]]
function m.mobile.getApps(pMobConnId)
  local mobileSessions = {}

  for idx, mobSession in pairs(test.mobileSession) do
    if pMobConnId == nil
      or getMobConnectionFromSession(mobSession) == test.mobileConnections[pMobConnId] then
        mobileSessions[idx] = mobSession
    end
  end

  return mobileSessions
end

--[[ @mobile.getAppsCount: get count of mobile applications on mobile connectuion
--! @parameters:
--! pMobConnId - script's mobile connection id (nil - means all mobile connections)
--! @return: mobile sessions count
--]]
function m.mobile.getAppsCount(pMobConnId)
  local sessions = m.mobile.getApps(pMobConnId)
  local count = 0
  for _, _ in pairs(sessions) do
    count = count + 1
  end
 return count
end

--[[ Functions of ptu submodule ]]

--[[ @ptu.getAppData: get application data for PTU
--! @parameters:
--! pAppId - script's mobile application id
--! @return: application data for PTU
--]]
function m.ptu.getAppData(pAppId)
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "Location-1" },
    AppHMIType = m.app.getParams(pAppId).appHMIType
  }
end

--[[ @ptu.getAppData: perform policy table update sequence
--! @parameters:
--! pPTUpdateFunc - function which contains updates for policy table
--! pExpNotificationFunc - specific notification function
--! @return: none
--]]
function m.ptu.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  if pExpNotificationFunc then
    pExpNotificationFunc()
  end
  local ptsFileName = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptuFileName = os.tmpname()
  local requestId = m.hmi.getConnection():SendRequest("SDL.GetURLS", { service = 7 })
  m.hmi.getConnection():ExpectResponse(requestId)
  :Do(function()
      m.hmi.getConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = ptsFileName })
      local ptuTable = getPTUFromPTS()
      for i, _ in pairs(m.mobile.getApps()) do
        ptuTable.policy_table.app_policies[m.app.getParams(i).fullAppID] = m.ptu.getAppData(i)
      end
      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
      local event = m.run.createEvent()
      m.hmi.getConnection():ExpectEvent(event, "PTU event")
      for id, _ in pairs(m.mobile.getApps()) do
        m.mobile.getSession(id):ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function()
            m.hmi.getConnection():ExpectRequest("BasicCommunication.SystemRequest")
            :Do(function(_, d3)
                if not pExpNotificationFunc then
                   m.hmi.getConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
                   m.hmi.getConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
                end
                m.hmi.getConnection():SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                m.hmi.getConnection():SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
              end)
            utils.cprint(35, "App ".. id .. " was used for PTU")
            m.hmi.getConnection():RaiseEvent(event, "PTU event")
            local corIdSystemRequest = m.mobile.getSession(id):SendRPC("SystemRequest", {
              requestType = "PROPRIETARY" }, ptuFileName)
            m.mobile.getSession(id):ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptuFileName) end)
          end)
        :Times(AtMost(1))
      end
    end)
end

--[[ Functions of app submodule ]]

--- Registration of application sequence
local function registerApp(pAppId, pMobConnId, hasPTU)
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end
  local session = m.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", m.app.getParams(pAppId))
      m.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.app.getParams(pAppId).appName } })
      :Do(function(_, d1)
          m.app.setHMIId(d1.params.application.appID, pAppId)
          if hasPTU then
            m.hmi.getConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
              :Do(function(_, d2)
                m.hmi.getConnection():SendResponse(d2.id, d2.method, "SUCCESS", { })
              end)
          end
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
        end)
    end)
end

--[[ @app.register: perform registration of application sequence with preparation to PTU
--! @parameters:
--! pAppId - script's mobile application id
--! pMobConnId - script's mobile connection id
--! @return: none
--]]
function m.app.register(pAppId, pMobConnId)
  registerApp(pAppId, pMobConnId, true)
end

--[[ @app.registerNoPTU: perform registration of application sequence without preparation to PTU
--! @parameters:
--! pAppId - script's mobile application id
--! pMobConnId - script's mobile connection id
--! @return: none
--]]
function m.app.registerNoPTU(pAppId, pMobConnId)
  registerApp(pAppId, pMobConnId, false)
end

--[[ @app.activate: perform activation of application sequence
--! @parameters:
--! pAppId - script's mobile application id
--! @return: none
--]]
function m.app.activate(pAppId)
  if not pAppId then pAppId = 1 end
  local requestId = m.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = m.app.getHMIId(pAppId) })
  m.hmi.getConnection():ExpectResponse(requestId)
  local params = m.app.getParams(pAppId)
  local audioStreamingState = "NOT_AUDIBLE"
  if params.isMediaApplication or
      utils.isTableContains(params.appHMIType, "NAVIGATION") or
      utils.isTableContains(params.appHMIType, "COMMUNICATION") then
    audioStreamingState = "AUDIBLE"
  end
  m.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = audioStreamingState, systemContext = "MAIN" })
  m.run.wait()
end

--[[ @app.unRegister: perform unregistration of application sequence
--! @parameters:
--! pAppId - script's mobile application id
--! @return: none
--]]
function m.app.unRegister(pAppId)
  if pAppId == nil then pAppId = 1 end
  local session = m.mobile.getSession(pAppId)
  local cid = session:SendRPC("UnregisterAppInterface", {})
  session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      m.mobile.deleteSession(pAppId)
    end)
  m.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = false, appID = m.app.getHMIId(pAppId) })
  :Do(function()
      m.app.deleteHMIId(pAppId)
    end)
end

--[[ @app.getParams: get application registration parameters
--! @parameters:
--! pAppId - script's mobile application id
--! @return: application registration parameters
--]]
function m.app.getParams(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams
end

--[[ @app.getHMIIds: get HMI application Ids collection
--! @parameters: none
--! @return: HMI Ids collection
--]]
function m.app.getHMIIds()
  local hmiIds = {}
  for _, id in pairs(hmiAppIds) do
    hmiIds[id.policyId] = id.hmiId
  end
  return hmiIds
end

--[[ @app.getHMIId: retrieve HMI application Id by script's mobile application id
--! @parameters:
--! pAppId - script's mobile application id
--! @return: HMI application Id
--]]
function m.app.getHMIId(pAppId)
  if not pAppId then pAppId = 1 end
  local id = hmiAppIds[getHmiAppIdKey(pAppId)]
  if id then
    return id.hmiId
  end
  return nil
end

--[[ @app.setHMIId: set HMI application Id by script's mobile application id
--! @parameters:
--! pHMIAppId - HMI application Id
--! pAppId - script's mobile application id
--! @return: none
--]]
function m.app.setHMIId(pHMIAppId, pAppId)
  if not pAppId then pAppId = 1 end
  hmiAppIds[getHmiAppIdKey(pAppId)] = {
    hmiId = pHMIAppId,
    policyId = getPolicyAppId(pAppId)
  }
end

--[[ @app.deleteHMIId: remove HMI application Id by script's mobile application id
--! @parameters:
--! pAppId - script's mobile application id
--! @return: none
--]]
function m.app.deleteHMIId(pAppId)
  hmiAppIds[getHmiAppIdKey(pAppId)] = nil
end

--[[ Functions of sdl submodule ]]

--[[ @sdl.getPathToFileInStorage: get path to file in SDL storage for specified mobile application
--! @parameters:
--! pFileName - file name
--! pAppId - script's mobile application id
--! @return: path to file in SDL storage
--]]
function m.sdl.getPathToFileInStorage(pFileName, pAppId)
  if not pAppId then pAppId = 1 end
  return commonPreconditions:GetPathToSDL() .. "storage/" .. m.app.getParams(pAppId).fullAppID .. "_"
    .. utils.getDeviceMAC() .. "/" .. pFileName
end

--[[ @sdl.getPathToFileInStorage: get parameter's value from SDL .ini file
--! @parameters:
--! pParamName - name of the parameter
--! @return: SDL parameter's value from ini file
--]]
function m.sdl.getSDLIniParameter(pParamName)
  return commonFunctions:read_parameter_from_smart_device_link_ini(pParamName)
end

--[[ @setSDLIniParameter: change original value of parameter in SDL .ini file
--! @parameters:
--! pParamName - name of the parameter
--! pParamValue - value to be set
--! @return: none
--]]
function m.sdl.setSDLIniParameter(pParamName, pParamValue)
  m.sdl.backupSDLIniFile()
  commonFunctions:write_parameter_to_smart_device_link_ini(pParamName, pParamValue)
end

--[[ @sdl.backupSDLIniFile: backup SDL .ini file
--! @parameters: none
--! @return: none
--]]
function m.sdl.backupSDLIniFile()
  if not m.sdl.isSdlIniBackuped then
    commonPreconditions:BackupFile("smartDeviceLink.ini")
    m.sdl.isSdlIniBackuped = true
  end
end

--[[ @sdl.restoreSDLIniFile: restore backuped SDL .ini file
--! @parameters: none
--! @return: none
--]]
function m.sdl.restoreSDLIniFile()
  if m.sdl.isSdlIniBackuped then
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
  end
end

--[[ @sdl.getPreloadedPTPath: get path to sdl preloaded_pt file
--! @parameters: none
--! @return: path to sdl preloaded_pt file
--]]
function m.sdl.getPreloadedPTPath()
  if not m.sdl.preloadedPTPath then
    local preloadedPTName = m.sdl.getSDLIniParameter("PreloadedPT")
    m.sdl.preloadedPTPath = commonPreconditions:GetPathToSDL() .. preloadedPTName
  end
  return m.sdl.preloadedPTPath
end

--[[ @sdl.backupPreloadedPT: backup sdl preloaded_pt file
--! @parameters: none
--! @return: none
--]]
function m.sdl.backupPreloadedPT()
  if not m.sdl.isPreloadedPTBackuped then
    commonPreconditions:BackupFile(m.sdl.getSDLIniParameter("PreloadedPT"))
    m.sdl.isPreloadedPTBackuped = true
  end
end

--[[ @sdl.restorePreloadedPT: restore backuped sdl preloaded_pt file
--! @parameters: none
--! @return: none
--]]
function m.sdl.restorePreloadedPT()
  if m.sdl.isPreloadedPTBackuped then
    commonPreconditions:RestoreFile(m.sdl.getSDLIniParameter("PreloadedPT"))
  end
end

--[[ @sdl.getPreloadedPT: get content of sdl preloaded_pt file
--! @parameters: none
--! @return: sdl preloaded_pt table
--]]
function m.sdl.getPreloadedPT()
  return utils.jsonFileToTable(m.sdl.getPreloadedPTPath())
end

--[[ @sdl.setPreloadedPT: set content into sdl preloaded_pt file
--! @parameters:
--! pPreloadedPT - table with content to be set into sdl preloaded_pt
--! @return: sdl preloaded_pt table
--]]
function m.sdl.setPreloadedPT(pPreloadedPT)
  m.sdl.backupPreloadedPT()
  utils.tableToJsonFile(pPreloadedPT, m.sdl.getPreloadedPTPath())
end

--[[ @sdl.start: start SDL
--! @parameters: none
--! @return: Expectation object for SDL start
--]]
function m.sdl.start()
  test:runSDL()
  return commonFunctions:waitForSDLStart(test)
end

--[[ @sdl.getStatus: Retrieve current status of SDL
--! @parameters: none
--! @return: current status of SDL (enum value, see SDL.lua)
--]]
function m.sdl.getStatus()
  return SDL:CheckStatusSDL()
end

--[[ @sdl.isRunning: Check whether SDL is running
--! @parameters: none
--! @return: boolean represents whether SDL is running
--]]
function m.sdl.isRunning()
  return SDL:CheckStatusSDL() == SDL.RUNNING
end

--[[ @sdl.stop: stop SDL
--! @parameters: none
--! @return: Expectation for SDL stop
--]]
function m.sdl.stop()
  event_dispatcher:ClearEvents()
  test.expectations_list:Clear()
  return SDL:StopSDL()
end

--[[ Functions of ATF extension ]]

--[[ @DeleteConnection: Remove connection from event dispatcher
--! @parameters:
--! pConnection - connection to be removed
--! @return: none
--]]
function event_dispatcher:DeleteConnection(pConnection)
  --ToDo: Implement
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
        return compareValues(arguments, data, "data")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(self, event, ret)
  test:AddExpectation(ret)
  return ret
end

--[[ @RaiseEvent: raise event on HMI connection
--! @parameters:
--! pEvent - event to be raised
--! pEventName - name of event to be raised
--! @return: none
--]]
function test.hmiConnection:RaiseEvent(pEvent, pEventName)
  if pEventName == nil then pEventName = "noname" end
  reporter.AddMessage(debug.getinfo(1, "n").name, pEventName)
  event_dispatcher:RaiseEvent(self, pEvent)
end

--[[ @ExpectEvent: register expectation for event on HMI connection
--! @parameters:
--! pEvent - event to expect
--! pEventName - name of event to expect
--! @return: Expectation object
--]]
function test.hmiConnection:ExpectEvent(pEvent, pEventName)
  if pEventName == nil then pEventName = "noname" end
  local ret = expectations.Expectation(pEventName, self)
  ret.event = pEvent
  event_dispatcher:AddEvent(self, pEvent, ret)
  test:AddExpectation(ret)
  return ret
end

--[[ Functions to support backward compatibility with old scripts ]]

--[[ @getConfigAppParams: return app's configuration from defined in config file
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier from configuration file
--]]
m.getConfigAppParams = m.app.getParams

--[[ @getAppDataForPTU: provide application data for PTU
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
m.getAppDataForPTU = m.ptu.getAppData

--[[ @policyTableUpdate: perform PTU
--! @parameters:
--! pPTUpdateFunc - function with additional updates (optional)
--! pExpNotificationFunc - function with specific expectations (optional)
--! @return: none
--]]
m.policyTableUpdate = m.ptu.policyTableUpdate

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
m.registerApp = m.app.register

--[[ @registerAppWOPTU: register mobile application and do not perform PTU
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
m.registerAppWOPTU = m.app.registerNoPTU

--[[ @activateApp: activate application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
m.activateApp = m.app.activate

--[[ @start: starting sequence: starting of SDL, initialization of HMI, connect mobile
--! @parameters:
--! pHMIParams - table with parameters for HMI initialization
--! @return: Start event expectation
--]]
function m.start(pHMIParams)
  local event = m.run.createEvent()
  m.init.SDL()
  :Do(function()
      m.init.HMI()
      :Do(function()
          m.init.HMI_onReady(pHMIParams)
          :Do(function()
              m.init.connectMobile()
              :Do(function()
                  m.init.allowSDL()
                  :Do(function()
                      m.hmi.getConnection():RaiseEvent(event, "Start event")
                    end)
                end)
            end)
        end)
    end)
  return m.hmi.getConnection():ExpectEvent(event, "Start event")
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

--[[ @postconditions: postcondition steps
--! @parameters: none
--! @return: none
--]]
function m.postconditions()
  StopSDL()
  m.sdl.restoreSDLIniFile()
  m.sdl.restorePreloadedPT()
end

--[[ @getMobileSession: get mobile session
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: mobile session object
--]]
function m.getMobileSession(pAppId, pMobConnId)
  if not pAppId then pAppId = 1 end
  local session = m.mobile.getSession(pAppId)
  if not session then
    session = m.mobile.createSession(pAppId, pMobConnId)
  end
  return session
end

--[[ @getMobileConnection: return Mobile connection object
--! @parameters: none
--! @return: Mobile connection object
--]]
m.getMobileConnection = m.mobile.getConnection

--[[ @getAppsCount: provide count of registered applications
--! @parameters: none
--! @return: count of apps
--]]
m.getAppsCount = m.mobile.getAppsCount

--[[ @getHMIConnection: return HMI connection object
--! @parameters: none
--! @return: HMI connection object
--]]
m.getHMIConnection = m.hmi.getConnection

--[[ @getHMIAppId: get HMI application identifier
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: application identifier
--]]
m.getHMIAppId = m.app.getHMIId

--[[ @setHMIAppId: set HMI application identifier
--! @parameters:
--! pHMIAppId - HMI application identifier
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
m.setHMIAppId = m.app.setHMIId

--[[ @getHMIAppIds: return array of all HMI application identifiers
--! @parameters: none
--! @return: array of all HMI application identifiers
--]]
m.getHMIAppIds = m.app.getHMIIds

--[[ @deleteHMIAppId: remove HMI application identifier
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
m.deleteHMIAppId = m.app.deleteHMIId

--[[ @getPathToFileInStorage: full path to file in storage folder
--! @parameters:
--! @pFileName - file name
--! @pAppId - application number (1, 2, etc.)
--! @return: path
--]]
m.getPathToFileInStorage = m.sdl.getPathToFileInStorage

--[[ @setSDLConfigParameter: change original value of parameter in SDL .ini file
--! @parameters:
--! pParamName - name of the parameter
--! pParamValue - value to be set
--! @return: none
--]]
m.setSDLIniParameter = m.sdl.setSDLIniParameter

--[[ @restoreSDLConfigParameters: restore original values of parameters in SDL .ini file
--! @parameters: none
--! @return: none
--]]
m.restoreSDLIniParameters = m.sdl.restoreSDLIniFile

return m
