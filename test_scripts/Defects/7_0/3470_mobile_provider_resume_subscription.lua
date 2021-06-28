---------------------------------------------------------------------------------------------------
-- TBA
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local manifest = {
  serviceName = config.application2.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application2.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local hashId

-- [[ Local Functions ]]
local function sendOnAppServiceData(pIsExp)
  local occurences = pIsExp == true and 1 or 0
  local params = {
    serviceData = {
      serviceType = manifest.serviceType,
      serviceID = common.getAppServiceID(2),
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
  }
  common.getMobileSession(2):SendNotification("OnAppServiceData", params)
  common.getMobileSession():ExpectNotification("OnAppServiceData", params):Times(occurences)
end

local function unexpectedDisconnect()
  local params = {
    serviceType = manifest.serviceType,
    subscribe = false
  }
  common.getMobileSession(2):ExpectRequest("GetAppServiceData", params)
  :Do(function(_, data)
    common.getMobileSession(2):SendResponse("GetAppServiceData", data.rpcCorrelationId, "SUCCESS")
  end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(common.mobile.getAppsCount())
  common.mobile.disconnect()
  utils.wait(1000)
end

local function ptUpdate(pt)
  pt.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceConsumerConfig(1);
  pt.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = common.getAppServiceProducerConfig(2, manifest.serviceType);
end

local function reRegisterApp()
  common.app.getParams().hashID = hashId
  common.app.registerNoPTU()
  local params = {
    serviceType = manifest.serviceType,
    subscribe = true
  }

  common.getMobileSession(2):ExpectRequest("GetAppServiceData", params)
  :Do(function(_, data)
    common.getMobileSession(2):SendResponse("GetAppServiceData", data.rpcCorrelationId, "SUCCESS")
  end)
end

local function subscribeAppService()
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
    hashId = data.payload.hashID
  end)

  common.mobileSubscribeAppServiceData(2, manifest.serviceType, 1)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerApp)
runner.Step("Activate app", common.activateApp)
runner.Step("PTU", common.policyTableUpdate, { ptUpdate })
runner.Step("Register app 2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app 2", common.activateApp, { 2 })
runner.Step("Publish App Service", common.publishMobileAppService, { manifest, 2 })

runner.Title("Test")
runner.Step("Subscribe to App Service Data", subscribeAppService)
runner.Step("Check subscription", sendOnAppServiceData, { true })
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Connect mobile", common.mobile.connect)
runner.Step("Register app 2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app 2", common.activateApp, { 2 })
runner.Step("Publish App Service", common.publishMobileAppService, { manifest, 2 })
runner.Step("Reregister App resumption data", reRegisterApp)
runner.Step("Check subscription", sendOnAppServiceData, { true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
