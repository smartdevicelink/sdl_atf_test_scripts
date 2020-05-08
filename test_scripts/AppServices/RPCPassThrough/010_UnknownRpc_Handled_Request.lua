---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 and app2 are registered on SDL.
--  2) AppServiceProvider permissions(with NAVIGATION AppService permissions to handle rpc FutureRequest) are assigned for <app1ID>
--  3) allow_unknown_rpc_passthrough is set to true for <app2ID>
--  4) app1 sends a PublishAppService (with {serviceType=NAVIGATION, handledRPC=FutureRequest} in the manifest)
--
--  Steps:
--  1) app2 sends a FutureRequest request to core
--
--  Expected:
--  1) Core forwards the request to app1
--  2) app1 responds to core with { success = true, resultCode = "SUCCESS", info = "Request was handled by app services" }
--  3) Core forwards the response from app1 to app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local rpcRequest = {
  name = "FutureRequest",
  hmi_name = "FutureInterface.FutureRequest",
  func_id = 956,
  params = {
    futureParam = 50,
    futureParam2 = { 50 },
    futureParam3 = "StringValue" 
  },
  hmi_params = {
    futureParam = 50,
    futureParam2 = { 50 },
    futureParam3 = "StringValue" 
  }
}

local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "NAVIGATION",
  handledRPCs = { rpcRequest.func_id },    
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  navigationServiceManifest = {}
}

local successResponse = {
  success = true,
  resultCode = "SUCCESS",
  info = "Request was handled by app services"
}

local rpcResponse = { 
  params = successResponse    
}

--[[ Local functions ]]
local function PTUfunc(tbl)
  --Add permissions for app1
  local pt_entry = common.getAppServiceProducerConfig(1)
  pt_entry.app_services.NAVIGATION = { handled_rpcs = {{function_id = rpcRequest.func_id}} }
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
  --Add permissions for app2
  pt_entry = common.getAppDataForPTU(2)
  pt_entry.groups = { "Base-4" }
  pt_entry.allow_unknown_rpc_passthrough = true
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = pt_entry
end

local function RPCPassThruTest()
  local providerMobileSession = common.getMobileSession(1)
  local mobileSession = common.getMobileSession(2)
  
  local cid = mobileSession:SendRPC(rpcRequest.func_id, rpcRequest.params)
      
  providerMobileSession:ExpectRequest(rpcRequest.func_id, rpcRequest.params):Do(function(_, data)
      providerMobileSession:SendResponse(rpcRequest.func_id, data.rpcCorrelationId, successResponse)
  end)

  --Core will NOT handle the RPC  
  EXPECT_HMICALL(rpcRequest.hmi_name, rpcRequest.hmi_params):Times(0)

  mobileSession:ExpectResponse(cid, rpcResponse.params)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)    
runner.Step("RAI App 1", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("PublishAppService", common.publishMobileAppService, { manifest, 1 })
runner.Step("RAI App 2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App", common.activateApp, { 2 })   

runner.Title("Test")    
runner.Step("RPCPassThroughTest_SUCCESS", RPCPassThruTest)   

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
