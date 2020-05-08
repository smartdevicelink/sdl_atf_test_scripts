---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application 1 with <appID> is registered on SDL.
--  2) AppServiceProvider permissions are assigned for <appID> with PublishAppService
--  3) Application 1 sends a PublishAppService RPC request with serviceType MEDIA
--
--  Steps:

--  2) HMI sends AppService.AppServiceActivation activate = false
--
--  Expected:
--  1) HMI receives a successful response with activate = false
--  2) Mobile app and HMI receive OnSystemCapabilityUpdated notification with updateReason = DEACTIVATED
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
  name = "AppService.AppServiceActivation",
  params = {
    activate = false
  }
}

local expectedResponse = {
  result = {
    activate = false
  },
  code = 0,
  method = "AppService.AppServiceActivation"
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession(1)
  local service_id = common.getAppServiceID()
  local requestParams = rpc.params
  requestParams.serviceID = service_id

  local cid = common.getHMIConnection():SendRequest(rpc.name, requestParams)  

  EXPECT_HMIRESPONSE(cid, expectedResponse):Times(1)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
  common.appServiceCapabilityUpdateParams("DEACTIVATED", manifest)):Times(AtLeast(1))

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("DEACTIVATED", manifest)):Times(AtLeast(1))
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
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

