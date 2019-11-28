---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1408
--
-- Preconditions:
-- 1. SDL and HMI started
-- 2. Devices are connected to SDL.
-- 3. App1 and App2 with SDL4.0 feature are registered from different devices
-- 4. query_app_response.json file is provided by both apps
-- 5. 6 apps are displayed on HMI
--
-- Steps:
-- 1. HMI sends SDL.ActivateApp to not registered SDL4.0 App3
-- SDL does:
-- a) send OnSystemRequest to foreground SDL4.0 app
-- 2. App is registered
-- SDL does:
-- a) set app to FULL HMI level
-- b) sends OnHMIStatus(FULL) to mobile App3
-- c) sends SDL.ActivateApp(SUCCESS) to HMI
-- d) sends BC.UpdateAppList to HMI with 6 apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local utils = require('user_modules/utils')
local actions = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
config.defaultProtocolVersion = 4
runner.testSettings.isSelfIncluded = false

--[[ Local Local Variables ]]
local file = "files/jsons/QUERRY_jsons/correctJSON.json"
local querryFileContent = utils.jsonFileToTable(file)
local app1Params = querryFileContent.response[1]
local app2Params = querryFileContent.response[2]

config.application3.registerAppInterfaceParams.appName = app2Params.name
config.application3.registerAppInterfaceParams.fullAppID = app2Params.appId

local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort },
  [2] = { host = "2.0.0.1", port = config.mobilePort }
}

local applicationsFromAppList = {}

--[[ Local Functions ]]
local function deleteMobDevice(pMobConnId)
  utils.deleteNetworkInterface(pMobConnId)
end

local function connectMobDevices(pDevices)
  for i = 1, #pDevices do
    utils.addNetworkInterface(i, pDevices[i].host)
    actions.mobile.createConnection(i, pDevices[i].host, pDevices[i].port)
    actions.mobile.connect(i)
  end
end

local function clearMobDevices(pDevices)
  for i = 1, #pDevices do
    deleteMobDevice(i)
  end
end

local function sdl4Function(pAppId)
  local session = actions.mobile.getSession(pAppId)
  session.correlationId = session.correlationId + 1

  local msg =
      {
        serviceType      = 7,
        frameInfo        = 0,
        rpcType          = 2,
        rpcFunctionId    = 32768,
        rpcCorrelationId = session.correlationId,
        payload          = '{"hmiLevel" :"FULL", "audioStreamingState" : "NOT_AUDIBLE", "systemContext" : "MAIN"}'
      }

  session:Send(msg)
  actions.mobile.getSession(pAppId):ExpectNotification("OnSystemRequest",
    { requestType = "LOCK_SCREEN_ICON_URL" },
    { requestType = "QUERY_APPS" })
  :Do(function(_,data)
      if data.payload.requestType == "QUERY_APPS" then
        local CorIdSystemRequest = actions.mobile.getSession(pAppId):SendRPC("SystemRequest",
        {
          requestType = "QUERY_APPS",
          fileName = "correctJSON.json"
        },
        file)
        actions.mobile.getSession(pAppId):ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
      end
    end)
  :Times(2)
end

local function registerSDL4App(pAppId, pMobConnId, pHasPTU)
  local appParams = actions.app.getParams(pAppId)
  local session = actions.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", appParams)
      local connection = session.mobile_session_impl.connection
      actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        {
          application = {
            appName = appParams.appName,
            deviceInfo = {
              name = utils.getDeviceName(connection.host, connection.port),
              id = utils.getDeviceMAC(connection.host, connection.port)
            }
          }
        })
      :Do(function(_, d1)
        actions.hmi.getConnection():ExpectRequest("VR.ChangeRegistration")
        actions.hmi.getConnection():ExpectRequest("TTS.ChangeRegistration")
        actions.hmi.getConnection():ExpectRequest("UI.ChangeRegistration")
        actions.app.setHMIId(d1.params.application.appID, pAppId)
          if pHasPTU then
            actions.isPTUStarted()
          end
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Do(function()
              sdl4Function(pAppId)
            end)
          session:ExpectNotification("OnPermissionsChange")
        end)
    end)
  actions.hmi.getConnection():ExpectRequest("BasicCommunication.UpdateAppList")
  :Do(function(_,data)
      applicationsFromAppList = data.params.applications
    end)
end

local function registerApp(pAppId, pMobConnId)
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end
  local session = actions.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(pAppId))
      actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = actions.app.getParams(pAppId).appName } })
      :Do(function(_, d1)
          actions.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
        end)
    end)
end

local function activationAppWithUpdateAppList()
  local hmiAppId
  for _, value in pairs(applicationsFromAppList) do
    if value.appName == actions.app.getParams(3).appName and
      value.deviceInfo.id == utils.getDeviceMAC(devices[2].host, devices[2].port) then
        hmiAppId = value.appID
    end
  end

  local expectedAppList = {
    { appName = actions.app.getParams(1).appName },
    { appName = actions.app.getParams(2).appName },
    { appName = actions.app.getParams(3).appName },
    { appName = app2Params.name },
    { appName = app1Params.name },
    { appName = app1Params.name }
  }

  actions.hmi.getConnection():ExpectRequest("BasicCommunication.UpdateAppList")
  :ValidIf(function(_,data)
    local actualAppList = {}
    for key, value in pairs(data.params.applications) do
      actualAppList[key] = { appName = value.appName }
    end
      if false == utils.isTableEqual(actualAppList, expectedAppList) then
        return false, "BC.UpdateAppList request got unexpected application list.\n" ..
          "Expected applications:\n" .. utils.tableToString(expectedAppList) .. "\n" ..
          "Actual application list:\n" .. utils.tableToString(actualAppList)
      end
      return true
    end)

  actions.mobile.getSession(2):ExpectNotification("OnSystemRequest",
    { requestType = "LAUNCH_APP" })
  :Do(function(_, data)
      if data.payload.requestType == "LAUNCH_APP" then
        registerApp(3, 2)
        actions.mobile.getSession(3):ExpectNotification("OnHMIStatus",
          { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
          { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
        :Times(2)
      end
    end)

  local requestId = actions.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = hmiAppId })
  actions.hmi.getConnection():ExpectResponse(requestId)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", actions.preconditions)
runner.Step("Start SDL and HMI", actions.start)
runner.Step("Connect two mobile devices to SDL", connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", registerSDL4App, {1, 1})
runner.Step("Register App2 from device 2", registerSDL4App, {2, 2})
runner.Step("Activation and registration App3 from device 2", activationAppWithUpdateAppList)

runner.Title("Postconditions")
runner.Step("Remove mobile devices", clearMobDevices, {devices})
runner.Step("Stop SDL", actions.postconditions)
