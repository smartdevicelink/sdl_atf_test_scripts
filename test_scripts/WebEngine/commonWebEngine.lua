---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local runner = require('user_modules/script_runner')
local events = require('events')
local test = require("user_modules/dummy_connecttest")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Shared Functions ]]
local common = {}
common.Title = runner.Title
common.Step = runner.Step
common.start = actions.start
common.stopSDL = actions.sdl.stop
common.getHMIConnection = actions.hmi.getConnection
common.registerApp = actions.registerApp
common.registerAppWOPTU = actions.registerAppWOPTU
common.activateApp = actions.activateApp
common.getMobileSession = actions.getMobileSession
common.cloneTable = utils.cloneTable
common.printTable = utils.printTable
common.tableToString = utils.tableToString
common.isTableEqual = utils.isTableEqual
common.wait = actions.run.wait
common.getAppsCount = actions.getAppsCount
common.cprint = utils.cprint
common.getConfigAppParams = actions.getConfigAppParams
common.policyTableUpdate = actions.policyTableUpdate
common.ptsTable = actions.sdl.getPTS
common.isPTUStarted = actions.isPTUStarted
common.failTestStep = actions.run.fail
common.getPreloadedPT = actions.sdl.getPreloadedPT
common.setPreloadedPT = actions.sdl.setPreloadedPT
common.null = actions.json.null
common.EMPTY_ARRAY = actions.json.EMPTY_ARRAY
common.sdlBuildOptions = test.sdlBuildOptions
common.deletePTS = actions.sdl.deletePTS
common.runAfter = actions.run.runAfter
common.unRegisterApp = actions.app.unRegister
common.backupSDLIniFile = actions.sdl.backupSDLIniFile
common.setSDLIniParameter = actions.sdl.setSDLIniParameter

--[[ Local Variables ]]
common.defaultAppProperties = {
  nicknames = { "Test Web Application_1", "Test Web Application_2" },
  policyAppID = "0000001",
  enabled = true,
  authToken = "ABCD12345",
  transportType = "WS",
  hybridAppPreference = "CLOUD",
  endpoint = "ws://127.0.0.1:8080/"
}

common.resultCode = {
  DATA_NOT_AVAILABLE = 9,
  INVALID_DATA = 11
}

common.wssCertificateCAname = "ca-cert.pem"
common.wssCertificateClientName = "client-cert.pem"
common.wssPrivateKeyName = "client-key.pem"
common.wssServerPrivateKeyName = "server-key.pem"
common.wssCertificateServerName = "server-cert.pem"

local aftCertPath = "./files/Security/WebEngine/"

config.wssCertificateCAPath = aftCertPath.. common.wssCertificateCAname
config.wssCertificateClientPath = aftCertPath .. common.wssCertificateClientName
config.wssPrivateKeyPath = aftCertPath .. common.wssPrivateKeyName


--[[ Common Functions ]]
local function getWebEngineConParams(pConnectionType)
  if pConnectionType == "WS" then return config.wsMobileURL, config.wsMobilePort end
  if pConnectionType == "WSS" then return config.wssMobileURL, config.wssMobilePort end
end

function common.validation(actualData, expectedData, pMessage)
  if true ~= common.isTableEqual(actualData, expectedData) then
    return false, pMessage .. " contains unexpected parameters.\n" ..
    "Expected table: " .. common.tableToString(expectedData) .. "\n" ..
    "Actual table: " .. common.tableToString(actualData) .. "\n"
  end
  return true
end

function common.setAppProperties(pData)
  local corId = common.getHMIConnection():SendRequest("BasicCommunication.SetAppProperties",
    { properties = pData })
  common.getHMIConnection():ExpectResponse(corId,
    { result = { code = 0 }})
end

function common.getAppProperties(pData)
  local sdlResponseDataResult = {}
  sdlResponseDataResult.code = 0
  sdlResponseDataResult.properties = { pData }
  local corId = common.getHMIConnection():SendRequest("BasicCommunication.GetAppProperties",
    { policyAppID = pData.policyAppID })
  common.getHMIConnection():ExpectResponse(corId, { result = sdlResponseDataResult })
  :ValidIf(function(_,data)
    return common.validation(data.result.properties, sdlResponseDataResult.properties,
      "BasicCommunication.GetAppProperties")
  end)
end

function common.updateDefaultAppProperties(pParam, pValue)
  local updatedAppProperties = common.cloneTable(common.defaultAppProperties)
  updatedAppProperties[pParam] = pValue
  return updatedAppProperties
end

function common.onAppPropertiesChange(pDataExpect, pTimes)
  if not pTimes then pTimes = 1 end
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppPropertiesChange",
    { properties = pDataExpect })
  :Times(pTimes)
  :ValidIf(function(_,data)
    return common.validation(data.params.properties, pDataExpect, "BasicCommunication.OnAppPropertiesChange")
  end)
end

function common.errorRPCprocessing(pRPC, pErrorCode, pData)
  if not pData then pData = {} end
  local corId = common.getHMIConnection():SendRequest("BasicCommunication." .. pRPC, pData)
  common.getHMIConnection():ExpectResponse(corId,
    { error = { code = pErrorCode, data = { method = "BasicCommunication." .. pRPC }}})
end

function common.errorRPCprocessingUpdate(pRPC, pErrorCode, pParam, pValue)
  local appPropertiesRequestData = common.updateDefaultAppProperties(pParam, pValue)
  common.errorRPCprocessing(pRPC, pErrorCode, { properties = appPropertiesRequestData })
end

function common.processRPCSuccess(pAppId, pRPC, pData)
  local responseParams = {}
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  local mobileSession = common.getMobileSession(pAppId)
  local cid = mobileSession:SendRPC(pRPC, pData)
  mobileSession:ExpectResponse(cid, responseParams)
end

function common.ignitionOff()
  local timeout = 5000
  local function removeSessions()
    for i = 1, common.getAppsCount() do
      test.mobileSession[i] = nil
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  common.getHMIConnection():ExpectEvent(event, "SDL shutdown")
  :Do(function()
      removeSessions()
      StopSDL()
      common.wait(1000)
    end)
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i = 1, common.getAppsCount() do
        common.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(common.getAppsCount())
  local isSDLShutDownSuccessfully = false
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      common.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      common.getHMIConnection():RaiseEvent(event, "SDL shutdown")
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      common.cprint(35, "SDL was shutdown forcibly")
      common.getHMIConnection():RaiseEvent(event, "SDL shutdown")
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

function common.connectWebEngine(pMobConnId, pConnectionType)
  local url, port = getWebEngineConParams(pConnectionType)
  actions.mobile.createConnection(pMobConnId, url, port, actions.mobile.CONNECTION_TYPE[pConnectionType])
  actions.mobile.connect(pMobConnId)
  :Do(function()
      local conType = config.defaultMobileAdapterType
      config.defaultMobileAdapterType = pConnectionType
      actions.mobile.allowSDL(pMobConnId)
      config.defaultMobileAdapterType = conType
    end)
end

function common.startWOdeviceConnect(pHMIParams)
  local event = actions.run.createEvent()
  actions.init.SDL()
  :Do(function()
      actions.init.HMI()
      :Do(function()
        actions.init.HMI_onReady(pHMIParams)
          :Do(function()
              actions.hmi.getConnection():RaiseEvent(event, "Start event")
            end)
        end)
    end)
  return actions.hmi.getConnection():ExpectEvent(event, "Start event")
end

function common.GetPathToSDL()
  return commonPreconditions:GetPathToSDL()
end

function common.preconditions()
  actions.preconditions()
  if config.defaultMobileAdapterType == "WSS" then
    common.addAllCertInSDLbinFolder()
    common.addAllCertInIniFile()
  else
    common.commentAllCertInIniFile()
  end
end

function common.postconditions()
  actions.postconditions()
  if config.defaultMobileAdapterType == "WSS" then
    common.removeAllCertFromSDLbinFolder()
  end
end

function common.addAllCertInSDLbinFolder()
  os.execute("cp -f " .. aftCertPath .. common.wssCertificateCAname .. " " .. common.GetPathToSDL())
  os.execute("cp -f " .. aftCertPath .. common.wssCertificateServerName .. " " .. common.GetPathToSDL())
  os.execute("cp -f " .. aftCertPath .. common.wssServerPrivateKeyName .. " " .. common.GetPathToSDL())
end

function common.removeAllCertFromSDLbinFolder()
  local command = "rm -f " .. common.GetPathToSDL() .. common.wssCertificateCAname .. " "
  .. common.GetPathToSDL() .. common.wssCertificateServerName .. " "
  .. common.GetPathToSDL() .. common.wssServerPrivateKeyName
  os.execute(command)
end

function common.addAllCertInIniFile()
  common.setSDLIniParameter("WSServerCertificatePath", common.wssCertificateServerName)
  common.setSDLIniParameter("WSServerKeyPath", common.wssServerPrivateKeyName)
  common.setSDLIniParameter("WSServerCACertificatePath", common.wssCertificateCAname)
end

function common.commentAllCertInIniFile()
  common.setSDLIniParameter("WSServerCertificatePath", ";")
  common.setSDLIniParameter("WSServerKeyPath", ";")
  common.setSDLIniParameter("WSServerCACertificatePath", ";")
end

function common.deviceNotConnected(pMobConnId)
  local connection = actions.mobile.getConnection(pMobConnId)
  connection:ExpectEvent(events.disconnectedEvent, "Disconnected")
  :Times(AnyNumber())
  :DoOnce(function()
      common.cprint(35, "Mobile #" .. pMobConnId .. " disconnected")
    end)
  connection:ExpectEvent(events.connectedEvent, "Connected")
  :Times(0)
  connection:Connect()
end

function common.connectWSSWebEngine()
  local url, port = getWebEngineConParams("WSS")
  actions.mobile.createConnection(1, url, port, actions.mobile.CONNECTION_TYPE.WSS)
  common.deviceNotConnected(1)
end

function common.checkUpdateAppList(pPolicyAppID, pTimes, pExpNumOfApps)
  if not pTimes then pTimes = 0 end
  if not pExpNumOfApps then pExpNumOfApps = 0 end
  common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateAppList")
  :Times(pTimes)
  :ValidIf(function(_,data)
    if #data.params.applications == pExpNumOfApps then
      if #data.params.applications ~= 0 then
        for i = 1,#data.params.applications do
          local app = data.params.applications[i]
          if app.policyAppID == pPolicyAppID then
            if app.isCloudApplication == false  then
              return true
            else
              return false, "Parameter isCloudApplication = " .. tostring(app.isCloudApplication) ..
              ", expected = false"
            end
          end
        end
        return false, "Application was not found in application array"
      else
        return true
      end
    else
      return false, "Application array in BasicCommunication.UpdateAppList contains " ..
        tostring(#data.params.applications)..", expected " .. tostring(pExpNumOfApps)
    end
  end)
  common.wait()
end

return common
