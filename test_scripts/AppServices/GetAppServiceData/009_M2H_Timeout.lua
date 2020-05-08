---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with GetAppServiceData
--  3) HMI has published a MEDIA service
--
--  Steps:
--  1) Application sends a GetAppServiceData RPC request with serviceType MEDIA
--
--  Expected:
--  1) SDL forwards the GetAppServiceData request to the HMI as AppService.GetAppServiceData
--  2) HMI sends a AppService.GetAppServiceData response (SUCCESS) to Core with its own serviceData
--  3) SDL forwards the response to Application as GetAppServiceData
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local manifest = {
  serviceName = "HMI_MEDIA_SERVICE",
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
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

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceConsumerConfig(1);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  local service_id = common.getAppServiceID(0)
  local responseParams = expectedResponse
  responseParams.serviceData.serviceID = service_id
  EXPECT_HMICALL(rpc.hmiName, rpc.params):Do(function(_, data)
    RUN_AFTER((function() 
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", 
        {
          serviceData = appServiceData
        })
    end), runner.testSettings.defaultTimeout + 2000) 
  end)


  mobileSession:ExpectResponse(cid, responseParams):Timeout(runner.testSettings.defaultTimeout + common.getRpcPassThroughTimeoutFromINI())
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishEmbeddedAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
