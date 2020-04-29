---------------------------------------------------------------------------------------------------
-- Description: Resumption of subscription for MEDIA app service data after unexpected disconnect

-- Precondition:
-- 1) Application with <appID> is registered on SDL.
-- 2) Specific permissions are assigned for <appID> with OnAppServiceData
-- 3) HMI has published a MEDIA service
-- 4) Application is subscribed to MEDIA app service data
-- 5) Transport reconnection is performed

-- Sequence:
-- 1. Mobile app registers with actual hashID
--   a. SDL starts data resumption
-- 2. SDL resumes subscription for MEDIA app service data sends AppService.GetAppServiceData request to HMI
--   a. HMI responds with success resultCode
-- 3. After success response from HMI SDL resumes the subscription
-- 4. HMI sends OnAppServiceData notification
--   a. SDL resend OnAppServiceData notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')
local test = require("user_modules/dummy_connecttest")
local events = require('events')
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[Local Variable]]
local hashID

--[[ Local Functions ]]
local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceConsumerConfig(1);
end

local manifest = {
  serviceName = "HMI_MEDIA_SERVICE",
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local rpc = {
  name = "OnAppServiceData",
  hmiName = "AppService.OnAppServiceData"
}

local appServiceData = {
  serviceType = manifest.serviceType,
  mediaServiceData = {
    mediaType = "MUSIC",
    mediaTitle = "Song name",
    mediaArtist = "Band name",
    mediaAlbum = "Album name",
    playlistName = "Good music",
    isExplicit = false,
    trackPlaybackProgress = 200,
    trackPlaybackDuration = 300,
    queuePlaybackProgress = 2200,
    queuePlaybackDuration = 4000,
    queueCurrentTrackNumber = 12,
    queueTotalTrackCount = 20
  }
}

local expectedNotification = {
  serviceData = appServiceData
}

local function processRPCSuccess()
  local mobileSession = common.getMobileSession()
  local service_id = common.getAppServiceID(0)
  local notificationParams = expectedNotification
  notificationParams.serviceData.serviceID = service_id

  common.getHMIConnection():SendNotification(rpc.hmiName, notificationParams)
  mobileSession:ExpectNotification(rpc.name, notificationParams)
end

local function checkResumption(pAppId)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE" },
    { hmiLevel = "FULL" })
  :Times(2)
end

local function reRegisterApp(pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession():StartService(7)
  :Do(function()
    local params = utils.cloneTable(common.getConfigAppParams(pAppId))
    params.hashID = hashID
    local corId = common.getMobileSession():SendRPC("RegisterAppInterface", params)
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = common.getConfigAppParams(pAppId).appName } })
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
        common.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
      end)
    end)
    checkResumption(pAppId)
end

local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  common.mobile.disconnect()
  utils.wait(1000)
end

local function connectMobile()
  test.mobileConnection:Connect()
  common.getMobileSession():ExpectEvent(events.connectedEvent, "Connected")
  :Do(function()
      utils.cprint(35, "Mobile connected")
    end)
end

local function mobileSubscribeAppServiceData(pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    hashID = data.payload.hashID
  end)
  common.mobileSubscribeAppServiceData(0)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("App activation", common.activateApp)
runner.Step("Publish App Service", common.publishEmbeddedAppService, { manifest })
runner.Step("Subscribe App Service Data", mobileSubscribeAppServiceData)

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Connect mobile", connectMobile)
runner.Step("App Reregistration", reRegisterApp)
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
