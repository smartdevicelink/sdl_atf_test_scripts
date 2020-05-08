---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application 1 with <appID> is registered on SDL.
--  2) Application 2 with <appID2> is registered on SDL.
--  3) Specific permissions are assigned for <appID> with PublishAppService
--  4) Specific permissions are assigned for <appID2> with PerformAppServiceInteraction
--  5) Application 2 is in the foreground
--  6) HMI has published a MEDIA service and is the active MEDIA service
--  7) Application 1 has published a MEDIA service
--
--  Steps:
--  1) Application 2 sends a PerformAppServiceInteraction RPC request with Application 1's serviceID
--     and requestServiceActive = true
--
--  Expected:
--  1) SDL activates Application 1's MEDIA service and broadcasts OnSystemCapabilityUpdated(APP_SERVICES) 
--  2) SDL forwards the PerformAppServiceInteraction request to Application 1
--  3) Application 1 sends a PerformAppServiceInteraction response (SUCCESS) to Core with a serviceSpecificResult
--  4) SDL forwards the response to Application 2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hmiManifest = {
  serviceName = "HMI_MEDIA_SERVICE",
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local rpc = {
  name = "PerformAppServiceInteraction",
  params = {
    originApp = config.application2.registerAppInterfaceParams.fullAppID,
    serviceUri = "mobile:sample.service.uri",
    requestServiceActive = true
  }
}

local expectedResponse = {
  serviceSpecificResult = "RESULT",
  success = true,
  resultCode = "SUCCESS"
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = common.getAppServiceConsumerConfig(2);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession(1)
  local mobileSession2 = common.getMobileSession(2)
  local service_id = common.getAppServiceID()
  local requestParams = rpc.params
  requestParams.serviceID = service_id
  local cid = mobileSession2:SendRPC(rpc.name, requestParams)

  -- Should not prompt user if app is in foreground
  EXPECT_HMICALL("AppService.GetActiveServiceConsent", { serviceID = service_id }):Times(0)
  local serviceParams = common.appServiceCapability("ACTIVATED", manifest)
  mobileSession:ExpectNotification("OnSystemCapabilityUpdated"):ValidIf(function(self, data)
      return common.findCapabilityUpdate(serviceParams, data.payload)
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated"):ValidIf(function(self, data)
      return common.findCapabilityUpdate(serviceParams, data.params)
    end)

  requestParams.requestServiceActive = nil
  mobileSession:ExpectRequest(rpc.name, requestParams):Do(function(_, data) 
      mobileSession:SendResponse(rpc.name, data.rpcCorrelationId, expectedResponse)
    end)

  mobileSession2:ExpectResponse(cid, expectedResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 2 })
runner.Step("Activate App", common.activateApp, { 2 })
runner.Step("Publish Embedded Service", common.publishEmbeddedAppService, { hmiManifest })
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
