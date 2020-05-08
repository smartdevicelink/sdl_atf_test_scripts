---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 and app2 are registered on SDL.
--  2) AppServiceProvider permissions(with NAVIGATION AppService permissions to handle rpc SendLocation) are assigned for <app1ID>
--  3) SendLocation permissions are assigned for <app2ID>
--  4) app1 sends a PublishAppService (with {serviceType=NAVIGATION, handledRPC=SendLocation} in the manifest)
--
--  Steps:
--  1) app2 sends a SendLocation request to core
--
--  Expected:
--  1) Core forwards the request to app1
--  2) app1 does not respond to the request in time
--  3) Core handles the original SendLocation request and sends {success = true, resultCode = "SUCCESS", info = nil} to app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "NAVIGATION",
  handledRPCs = { 39 },    
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  navigationServiceManifest = {}
}

local successResponse = {
  success = true,
  resultCode = "SUCCESS",
  info = "Request was handled by app services"
}

local rpcRequest = {
  name = "SendLocation",
  hmi_name = "Navigation.SendLocation",
  params = {
    longitudeDegrees = 50,
    latitudeDegrees = 50,
    locationName = "TestLocation" 
  },
  hmi_params = {
    longitudeDegrees = 50,
    latitudeDegrees = 50,
    locationName = "TestLocation" 
  }
}

local rpcResponse = { 
  params = {success = true, resultCode = "SUCCESS", info = nil},
  hmi_result = {
    code = "SUCCESS",
    params = {}
  }    
}

--[[ Local functions ]]
local function PTUfunc(tbl)
  --Add permissions for app1
  local pt_entry = common.getAppServiceProducerConfig(1)
  pt_entry.app_services.NAVIGATION = { handled_rpcs = {{function_id = 39}} }
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
  --Add permissions for app2
  pt_entry = common.getAppDataForPTU(2)
  pt_entry.groups = { "Base-4" , "SendLocation" }
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = pt_entry
end

local function RPCPassThruTest()
  local providerMobileSession = common.getMobileSession(1)
  local mobileSession = common.getMobileSession(2)
  
  local cid = mobileSession:SendRPC(rpcRequest.name, rpcRequest.params)
      
  providerMobileSession:ExpectRequest(rpcRequest.name, rpcRequest.params):Do(function(_, data)
    RUN_AFTER((function()
      providerMobileSession:SendResponse(rpcRequest.name, data.rpcCorrelationId, successResponse)
    end), common.getRpcPassThroughTimeoutFromINI() + 1000)
  end)
  
  --Core will handle the RPC
  EXPECT_HMICALL(rpcRequest.hmi_name, rpcRequest.hmi_params):Times(1)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, rpcResponse.hmi_result.code, rpcResponse.hmi_result.params)
  end)        

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
runner.Step("RPCPassThroughTest_TIMEOUT", RPCPassThruTest)   

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
