---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application 1 with <appID> is registered on SDL.
--  2) Application 2 with <appID2> is registered on SDL.
--  3) AppServiceProvider permissions are assigned for <appID> with PublishAppService
--  4) AppServiceConsumer permissions are assigned for <appID2> with GetSystemCapability
--
--  Steps:
--  1) Application 2 sends a GetSystemCapability RPC request with subscribe = true
--  2) Application 1 sends a PublishAppService RPC request with serviceType MEDIA
--
--  Expected:
--  1) App 2 gets a GetSystemCapability response SUCCESS
--  2) App 1, App 2, and HMI, all get OnSystemCapabilityUpdated notifications
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
  mediaServiceManifest = {
    futureMediaData = "future media data"
  },
  futureManifestStruct = {
    futureStructItem = "future struct item"
  }
}

local rpc = {
  name = "GetSystemCapability",
  params = {
    systemCapabilityType = "APP_SERVICES",
    subscribe = true
  }
}

local expectedResponse = {
  success = true,
  resultCode = "SUCCESS"
}

local publishRpc = {
  name = "PublishAppService",
  params = {
    appServiceManifest = manifest
  }
}

local publishExpectedResponse = {
  appServiceRecord = {
    serviceManifest = manifest,
    servicePublished = true,
    serviceActive = true
  },
  success = true,
  resultCode = "SUCCESS"
}

--[[ Local Functions ]]
local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = common.getAppServiceConsumerConfig(2);
end

local function GetSystemCapabilitySubscribe(self)
  local mobileSession2 = common.getMobileSession(2)
  local cid = mobileSession2:SendRPC(rpc.name, rpc.params)
  local responseParams = expectedResponse

  mobileSession2:ExpectResponse(cid, responseParams)
end

local function PublishServiceExpectNotification(self)
  local mobileSession = common.getMobileSession(1)
  local mobileSession2 = common.getMobileSession(2)
  local cid = mobileSession:SendRPC(publishRpc.name, publishRpc.params)

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(2)
  
  mobileSession2:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(2)

  mobileSession:ExpectResponse(cid, publishExpectedResponse)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 2 })
runner.Step("Activate App", common.activateApp)
runner.Step("Activate App", common.activateApp, { 2 })
runner.Step("Set config.ValidateSchema = false", common.setValidateSchema, {false})

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", GetSystemCapabilitySubscribe)
runner.Step("Publish Service and expect OnSystemCapabilityUpdate", PublishServiceExpectNotification)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
