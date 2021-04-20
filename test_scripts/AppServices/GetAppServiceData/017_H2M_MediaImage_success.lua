---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with GetAppServiceData
--  3) Application has published a MEDIA service
--  4) Application does a putfile with an image
--
--  Steps:
--  1) HMI sends a AppService.GetAppServiceData RPC request with serviceType MEDIA
--
--  Expected:
--  1) SDL forwards the GetAppServiceData request to Application as GetAppServiceData
--  2) Application sends a GetAppServiceData response (SUCCESS) to Core with its own serviceData
--  3) SDL forwards the response to HMI as AppService.GetAppServiceData. The mediaImage value is the full file path of the image.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local deviceMAC = utils.getDeviceMAC()
local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. deviceMAC .. "/")


local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  navigationServiceManifest = {
    acceptsWayPoints = true
  }
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
    queueTotalTrackCount = 20,
    mediaImage = {
      value = "icon_png.png",
      imageType = "DYNAMIC"
    }
  },
  success = true,
  resultCode = "SUCCESS"
}

local hmiServiceData = {
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
    queueTotalTrackCount = 20,
    mediaImage = {
      value = storagePath .. "icon_png.png",
      imageType = "DYNAMIC"
    }
  },
  success = true,
  resultCode = "SUCCESS"
}

local rpc = {
  name = "GetAppServiceData",
  hmiName = "AppService.GetAppServiceData",
  params = {
    serviceType = manifest.serviceType
  }
}

local expectedResponse = {
  serviceData = appServiceData,
  success = true,
  resultCode = "SUCCESS"
}

local putFileParams = {
  syncFileName = "icon_png.png",
  fileType ="GRAPHIC_PNG",
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1, manifest.serviceType);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession()
  local cid = common.getHMIConnection():SendRequest(rpc.hmiName, rpc.params)
  local service_id = common.getAppServiceID()
  local responseParams = expectedResponse
  responseParams.serviceData.serviceID = service_id
  mobileSession:ExpectRequest(rpc.name, rpc.params):Do(function(_, data) 
      mobileSession:SendResponse(rpc.name, data.rpcCorrelationId, responseParams)
    end)

  EXPECT_HMIRESPONSE(cid, {
    result = {
      serviceData = hmiServiceData,
      code = 0, 
      method = rpc.hmiName
    }
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })
runner.Step("Putfile", common.putFileInStorage, {1, putFileParams, result})

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
