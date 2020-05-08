---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application 1 with <appID> is registered on SDL.
--  2) Application 2 with <appID2> is registered on SDL.
--  3) Specific permissions are assigned for <appID> with PublishAppService
--  4) Specific permissions are assigned for <appID2> with PerformAppServiceInteraction
--  5) Application 1 has published a MEDIA service
--
--  Steps:
--  1) Application 2 sends a PerformAppServiceInteraction RPC request with Application 1's serviceID
--
--  Expected:
--  1) SDL forwards the PerformAppServiceInteraction request to Application 1
--  2) Application 1 sends a PerformAppServiceInteraction response (SUCCESS) to Core with a serviceSpecificResult
--  3) SDL forwards the response to Application 2
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
  name = "PerformAppServiceInteraction",
  params = {
    originApp = config.application2.registerAppInterfaceParams.fullAppID,
    serviceUri = "mobile:sample.service.uri"
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
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

