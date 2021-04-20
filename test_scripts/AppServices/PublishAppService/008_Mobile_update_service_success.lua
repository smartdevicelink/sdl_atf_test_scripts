---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with PublishAppService
--  3) App sends a PublishAppService RPC request
--
--  Steps:
--  1) App sends a PublishAppService RPC request with "allowAppConsumers = false" to update the service record.
--
--  Expected:
--  1) SDL sends a OnSystemCapabilityUpdated(APP_SERVICES, MANIFEST_UPDATE) notification to mobile app
--  2) SDL responds to mobile app with "resultCode: SUCCESS, success: true"
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

local manifestUpdate = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = false,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local rpc = {
  name = "PublishAppService",
  params = {
    appServiceManifest = manifestUpdate
  }
}

local expectedResponse = {
  appServiceRecord = {
    serviceManifest = manifestUpdate,
    servicePublished = true,
    serviceActive = true
  },
  success = true,
  resultCode = "SUCCESS"
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("MANIFEST_UPDATE", manifestUpdate)):Times(1)
  mobileSession:ExpectResponse(cid, expectedResponse)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("MANIFEST_UPDATE", manifestUpdate)):Times(1)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "Update_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

