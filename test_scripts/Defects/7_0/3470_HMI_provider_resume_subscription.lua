---------------------------------------------------------------------------------------------------
-- TBA
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local manifest = {
  serviceName = "HMI_MEDIA_SERVICE",
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = common.getConfigAppParams(1).syncMsgVersion,
  mediaServiceManifest = {}
}
local serviceId
local hashId

-- [[ Local Functions ]]
local function publishEmbeddedAppService()
  local cid = common.getHMIConnection():SendRequest("AppService.PublishAppService", {
    appServiceManifest = manifest })
  common.getHMIConnection():ExpectResponse(cid, {
    result = {
      appServiceRecord = {
        serviceManifest = manifest,
        servicePublished = true
      },
      code = 0,
      method = "AppService.PublishAppService"
    }
  })
  :Do(function(_, data)
    serviceId = data.result.appServiceRecord.serviceID
    end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSystemCapabilityUpdated")
  :Times(2)
end

local function subscribeAppServiceData(pIsSubscribed)
  local params = {
    serviceType = manifest.serviceType,
    subscribe = pIsSubscribed
  }
  local cid = common.getMobileSession():SendRPC("GetAppServiceData", params)
  common.getHMIConnection():ExpectRequest("AppService.GetAppServiceData")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
end

local function sendOnAppServiceData(pIsExp)
  local occurences = pIsExp == true and 1 or 0
  local params = {
    serviceData = {
      serviceType = manifest.serviceType,
      serviceID = serviceId,
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
  common.getHMIConnection():SendNotification("AppService.OnAppServiceData", params)
  common.getMobileSession():ExpectNotification("OnAppServiceData", params):Times(occurences)
end

local function unexpectedDisconnect()
  local params = {
    serviceType = manifest.serviceType,
    subscribe = false
  }
  common.getHMIConnection():ExpectRequest("AppService.GetAppServiceData", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(common.mobile.getAppsCount())
  common.mobile.disconnect()
  utils.wait(1000)
end

local function ptUpdate(pt)
  pt.policy_table.app_policies[common.app.getPolicyAppId()].groups = { "Base-4", "AppServiceConsumer" }
end

local function reRegisterApp()
  common.app.getParams().hashID = hashId
  common.app.registerNoPTU()
  local params = {
    serviceType = manifest.serviceType,
    subscribe = true
  }
  common.getHMIConnection():ExpectRequest("AppService.GetAppServiceData", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerApp)
runner.Step("Activate app", common.activateApp)
runner.Step("PTU", common.policyTableUpdate, { ptUpdate })
runner.Step("Publish Embedded App Service", publishEmbeddedAppService, { manifest })

runner.Title("Test")
runner.Step("Subscribe to App Service Data", subscribeAppServiceData, { true })
runner.Step("Check subscription", sendOnAppServiceData, { true })
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Connect mobile", common.mobile.connect)
runner.Step("Reregister App resumption data", reRegisterApp)
runner.Step("Check subscription", sendOnAppServiceData, { true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
