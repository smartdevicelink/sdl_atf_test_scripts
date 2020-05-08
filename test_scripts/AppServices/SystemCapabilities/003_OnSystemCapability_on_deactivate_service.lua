---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application 1 with <appID> is registered on SDL.
--  2) Application 2 with <appID2> is registered on SDL.
--  3) AppServiceProvider permissions are assigned for <appID> with PublishAppService
--
--  Steps:
--  1) Application 1 sends a PublishAppService RPC request with serviceType MEDIA
--  2) Application 2 sends a GetSystemCapability RPC request with subscribe true
--  3) HMI sends ActivateAppService:false
--
--  Expected:
--  1) SDL responds with GetSystemCapability SUCCESS
--  2) SDL send OnSystemCapabilityUpdated:DEACTIVATED after HMI deactivates the servce
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

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
end

--[[ Local Functions ]]
local function GetSystemCapabilitySubscribe(self)
  local mobileSession2 = common.getMobileSession(2)
  local cid = mobileSession2:SendRPC(rpc.name, rpc.params)
  local responseParams = expectedResponse
  responseParams["systemCapability"]  = common.appServiceCapabilityUpdateParams("ACTIVE", manifest).systemCapability
  responseParams.systemCapability.appServicesCapabilities.appServices[1].updateReason = nil
  mobileSession2:ExpectResponse(cid, responseParams)
end

local function DeactivateServiceExpectNotification(self)
  local mobileSession = common.getMobileSession(1)
  local mobileSession2 = common.getMobileSession(2)
  local cid = common.getHMIConnection():SendRequest("AppService.AppServiceActivation", {
    activate = false,
    serviceID = common.getAppServiceID()
  })

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
  common.appServiceCapabilityUpdateParams("DEACTIVATED", manifest)):Times(1)

  mobileSession2:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("DEACTIVATED", manifest)):Times(1)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
  common.appServiceCapabilityUpdateParams("DEACTIVATED", manifest)):Times(1)
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
runner.Step("Activate App", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", GetSystemCapabilitySubscribe)
runner.Step("Disconnect app service and expect OnSystemCapabilityUpdate", DeactivateServiceExpectNotification)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

