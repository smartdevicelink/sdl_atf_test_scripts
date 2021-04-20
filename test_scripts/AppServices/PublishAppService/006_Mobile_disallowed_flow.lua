---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) AppServiceProvider permissions are assigned for <appID> with PublishAppService
--
--  Steps:
--  1) Application sends a PublishAppService RPC request for service type NAVIGATION
--  2) Application sends a PublishAppService RPC request with service_name = "BadServiceName"
--  3) Application sends a PublishAppService RPC request with handled_rpc = {44}
--
--  Expected for each step:
--  1) SDL does NOT send a OnSystemCapabilityUpdated(APP_SERVICES, PUBLISHED) notification to mobile app
--  2) SDL does NOT send a OnSystemCapabilityUpdated(APP_SERVICES, ACTIVATED) notification to mobile app
--  3) SDL responds to mobile app with "resultCode: DISALLOWED"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "NAVIGATION",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local rpc = {
  name = "PublishAppService",
  params = {
    appServiceManifest = manifest
  }
}

local expectedResponse = {
  resultCode = "DISALLOWED"
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1, "WEATHER");
end

--[[ Local Functions ]]
local function processServiceTypeDisallowed(self)
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(0)
  mobileSession:ExpectResponse(cid, expectedResponse)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
  common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
  common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(0)
end

local function processServiceNameDisallowed(self)
  rpc.params.appServiceManifest.serviceType = "WEATHER"
  rpc.params.appServiceManifest.serviceName = "BadServiceName"
  
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(0)
  mobileSession:ExpectResponse(cid, expectedResponse)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
  common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
  common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(0)
end

local function processHandledRPCsDisallowed(self)
  rpc.params.appServiceManifest.serviceName = config.application1.registerAppInterfaceParams.appName
  rpc.params.appServiceManifest["handledRPCs"] = {44}
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(0)
  mobileSession:ExpectResponse(cid, expectedResponse)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
  common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
  common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_disallowed_by_service_type", processServiceTypeDisallowed)
runner.Step("RPC " .. rpc.name .. "_disallowed_by_service_name", processServiceNameDisallowed)
runner.Step("RPC " .. rpc.name .. "_disallowed_by_handled_rpcs", processHandledRPCsDisallowed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

