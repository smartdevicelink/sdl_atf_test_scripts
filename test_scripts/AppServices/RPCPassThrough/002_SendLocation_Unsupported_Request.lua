---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 and app2 are registered on SDL.
--  2) AppServiceProvider permissions(with NAVIGATION AppService permissions to handle rpc SendLocation) are assigned for <app1ID>
--  3) SendLocation permissions are assigned for <app2ID>
--  4) app1 sends a PublishAppService (with {serivceType=NAVIGATION, handledRPC=SendLocation} in the manifest)
--
--  Steps:
--  1) app2 sends a SendLocation request to core
--
--  Expected:
--  1) Core forwards the request to app1
--  2) app1 responds to core with { success = false, resultCode = "UNSUPPORTED_REQUEST", info = "Request CANNOT be handled by app services" }
--  3) Core handles the original SendLocation request and sends {success = true, resultCode = "SUCCESS", info = nil} to app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local functions ]]
local function PTUfunc(tbl)
  local pt_entry = common.getAppServiceProducerConfig(1)
  pt_entry.app_services.NAVIGATION = { handled_rpcs = {{function_id = 39}} }
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
  pt_entry = common.getAppDataForPTU(2)
  pt_entry.groups = { "Base-4" , "SendLocation" }
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = pt_entry;
end

local function RPCPassThruTest(rpc, expectedResponse, passThruResponse)
  local providerMobileSession = common.getMobileSession(1)
  local MobileSession = common.getMobileSession(2)

  local cid = MobileSession:SendRPC(rpc.name, rpc.params)
      
  providerMobileSession:ExpectRequest(rpc.name, rpc.params):Do(function(_, data)
    providerMobileSession:SendResponse(rpc.name, data.rpcCorrelationId, passThruResponse)
  end)


  --Core will handle the RPC
  if rpc.hmi_name then
    EXPECT_HMICALL(rpc.hmi_name, requestParams):Times(1)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, expectedResponse.hmi_params.code, expectedResponse.hmi_params)
    end)        
  end

  MobileSession:ExpectResponse(cid, expectedResponse.params)

end

--[[ Local variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "NAVIGATION",
  handledRPCs = {39},    
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  navigationServiceManifest = {}
}

local unsupportedResponse = {
  success = false,
  resultCode = "UNSUPPORTED_REQUEST",
  info = "Request CANNOT be handled by app services"
}

local coreResult = {success = true, resultCode = "SUCCESS", info = nil}

local sendLocationRequest = { 
  name = "SendLocation",
  hmi_name = "Navigation.SendLocation",
  params = {
    longitudeDegrees = 50,
    latitudeDegrees = 50,
    locationName = "TestLocation" 
  },
  hmi_params = params
}

local sendLocationResponse = { 
  name = "SendLocation",
  hmi_name = "Navigation.SendLocation",
  params = coreResult,
  hmi_params = { code = 0 }
}

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
runner.Step("RPCPassThroughTest_UNSUPPORTED", RPCPassThruTest, { sendLocationRequest, sendLocationResponse, unsupportedResponse})   

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
