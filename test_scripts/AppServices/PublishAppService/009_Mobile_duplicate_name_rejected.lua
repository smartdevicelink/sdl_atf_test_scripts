---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application1 with <appID> is registered on SDL.
--  2) Application2 with <appID2> is registered on SDL.
--  3) Specific permissions are assigned for <appID> with PublishAppService
--  4) Specific permissions are assigned for <appID2> with PublishAppService
--  5) Application1 has published a MEDIA service with it's app name for `serviceName`
--
--  Steps:
--  1) Application2 sends a PublishAppService(NAVIGATION) RPC request service with Application1's 
--     app name for `serviceName`
--
--  Expected:
--  1) SDL responds to mobile app with "resultCode: REJECTED, success: false"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local manifest2 = {
  serviceName = manifest.serviceName,
  serviceType = "NAVIGATION",
  allowAppConsumers = false,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local rpc = {
  name = "PublishAppService",
  params = {
    appServiceManifest = manifest2
  }
}

local expectedResponse = {
  success = false,
  resultCode = "REJECTED"
}

local function PTUfunc(tbl)
  local appConfig = common.getAppServiceProducerConfig(1);
  local appConfig2 = common.getAppServiceProducerConfig(2, manifest2.serviceType);
  appConfig2.app_services[manifest2.serviceType].service_names = { 
    manifest.serviceName
  }

  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = appConfig;
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = appConfig2;
end

--[[ Local Functions ]]

local function processRPCRejected(self)
  local mobileSession = common.getMobileSession(2)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated"):Times(0)
  mobileSession:ExpectResponse(cid, expectedResponse)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated"):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 2 })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_REJECTED", processRPCRejected)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

