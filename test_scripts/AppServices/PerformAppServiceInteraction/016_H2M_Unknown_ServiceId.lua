---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with PublishAppService
--  3) Application 1 has published a MEDIA service
--
--  Steps:
--  1) HMI sends a AppService.PerformAppServiceInteraction RPC request with Application's serviceID
--
--  Expected:
--  1) SDL responds to the HMI with {code = "INVALID_ID"}
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

local hmiOriginID = "HMI_ORIGIN_ID"

local rpc = {
  name = "PerformAppServiceInteraction",
  hmiName = "AppService.PerformAppServiceInteraction",
  params = {
    serviceUri = "mobile:sample.service.uri"
  }
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession()
  local service_id = common.getAppServiceID()
  local requestParams = rpc.params
  requestParams.serviceID = "not a service id"
  local cid = common.getHMIConnection():SendRequest(rpc.hmiName, requestParams)
  local passedRequestParams = requestParams
  passedRequestParams.originApp = hmiOriginID
  
  -- Request is NOT forwarded to ASP
  mobileSession:ExpectRequest(rpc.name, passedRequestParams):Times(0)

  EXPECT_HMIRESPONSE(cid, {
    result = {
      serviceSpecificResult = nil,
      code = 13,  --INVALID_ID (HMI_API)
      data = { 
        method = rpc.hmiName
      }
    }
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set HMI Origin ID", common.setSDLIniParameter, { "HMIOriginID", hmiOriginID })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_INVALID_ID", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
