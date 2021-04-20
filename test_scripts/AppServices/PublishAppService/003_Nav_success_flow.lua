---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) AppServiceProvider permissions are assigned for <appID> with PublishAppService
--
--  Steps:
--  1) Application sends a PublishAppService RPC request for service type NAVIGATION
--
--  Expected:
--  1) SDL sends a OnSystemCapabilityUpdated(APP_SERVICES, PUBLISHED) notification to mobile app and HMI
--  2) SDL sends a OnSystemCapabilityUpdated(APP_SERVICES, ACTIVATED) notification to mobile app and HMI
--  3) SDL sends a OnSystemCapabilityUpdated(NAVIGATION) notification to the HMI
--  4) SDL responds to mobile app with "resultCode: SUCCESS, success: true"
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
  appServiceRecord = {
    serviceManifest = manifest,
    servicePublished = true,
    serviceActive = true
  },
  success = true,
  resultCode = "SUCCESS"
}

local expectedNavCapabilities = {
  systemCapability = 
  {
      systemCapabilityType = "NAVIGATION",
      navigationCapability = 
      {
          getWayPointsEnabled = true,
          sendLocationEnabled = true
      }
  }
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1, "NAVIGATION");
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(2)
  mobileSession:ExpectResponse(cid, expectedResponse)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest), expectedNavCapabilities):Times(3)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

