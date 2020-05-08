---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with PublishAppService
--  3) App sends a PublishAppService RPC request
--  4) Application with <appID2> is registered on SDL.
--
--  Steps:
--  1) App2 sends a UnpublishAppService RPC to core
--
--  Expected:
--  1) SDL responds to mobile app2 with "resultCode: INVALID_ID, success: false"
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

local rpc = {
  name = "UnpublishAppService",
  params = {
    serviceID = "temp"
  }
}

local expectedResponse = {
  success = false,
  resultCode = "INVALID_ID"
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = common.getAppServiceProducerConfig(2);
end

--[[ Local Functions ]]
local function processRPCFailure(self)
  rpc.params.serviceID = common.getAppServiceID(1)
  local mobileSession = common.getMobileSession(2)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("REMOVED", manifest)):Times(0)
  mobileSession:ExpectResponse(cid, expectedResponse)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("REMOVED", manifest)):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })
runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 2 })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "Update_resultCode_INVALID_ID", processRPCFailure)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

