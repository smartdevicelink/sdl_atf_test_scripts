---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1, app2 and app3 are registered on SDL.
--  2) AppServiceProvider permissions(with NAVIGATION AppService permissions to handle rpc SendLocation) are assigned for <app1ID>
--  3) AppServiceProvider permissions(with MEDIA AppService permissions to handle rpc SendLocation) are assigned for <app2ID>
--  4) SendLocation permissions are assigned for <app3ID>
--  5) app1 sends a PublishAppService (with {serviceType=NAVIGATION, handledRPC=SendLocation} in the manifest)
--  6) app2 sends a PublishAppService (with {serviceType=MEDIA, handledRPC=SendLocation} in the manifest)
--
--  Steps:
--  1) app3 sends a SendLocation request to core
--
--  Expected:
--  1) Core forwards the request to app1
--  2) app1 responds to core with { success = false, resultCode = "UNSUPPORTED_REQUEST", info = "Request CANNOT be handled by app services" }
--  3) Core forwards the request to app2
--  2) app2 responds to core with { success = true, resultCode = "SUCCESS", info = "Request was handled by app services" }
--  3) Core forwards the response from app2 to app3
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

local manifest2 = {
  serviceName = config.application2.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  handledRPCs = { 39 },    
  allowAppConsumers = true,
  rpcSpecVersion = config.application2.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local unsupportedResponse = {
  success = false,
  resultCode = "UNSUPPORTED_REQUEST",
  info = "Request CANNOT be handled by app services"
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
  params = successResponse    
}

--[[ Local functions ]]
local function PTUfunc(tbl)
  --Add permissions for app1
  local pt_entry = common.getAppServiceProducerConfig(1)
  pt_entry.app_services.NAVIGATION = { handled_rpcs = {{function_id = 39}} }
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
  --Add permissions for app2
  pt_entry = common.getAppServiceProducerConfig(2)
  pt_entry.app_services.MEDIA.handled_rpcs = {{function_id = 39}}
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = pt_entry
  --Add permissions for app3
  pt_entry = common.getAppDataForPTU(3)
  pt_entry.groups = { "Base-4" , "SendLocation" }
  tbl.policy_table.app_policies[common.getConfigAppParams(3).fullAppID] = pt_entry
end

local function RPCPassThruTest()
  local firstProviderMobileSession = common.getMobileSession(1)
  local secondProviderMobileSession = common.getMobileSession(2)
  local mobileSession = common.getMobileSession(3)
  local canHandleRequest = false

  local cid = mobileSession:SendRPC(rpcRequest.name, rpcRequest.params)
      
  firstProviderMobileSession:ExpectRequest(rpcRequest.name, rpcRequest.params):Do(function(_, data)
    local ASPResponse = successResponse 
    if not canHandleRequest then
      canHandleRequest = true
      ASPResponse = unsupportedResponse
    end
    firstProviderMobileSession:SendResponse(rpcRequest.name, data.rpcCorrelationId, ASPResponse)
  end)
  
  secondProviderMobileSession:ExpectRequest(rpcRequest.name, rpcRequest.params):Do(function(_, data)
    local ASPResponse = successResponse 
    if not canHandleRequest then
      canHandleRequest = true
      ASPResponse = unsupportedResponse
    end
    secondProviderMobileSession:SendResponse(rpcRequest.name, data.rpcCorrelationId, ASPResponse)
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
runner.Step("Publish NAVIGATION AppService", common.publishMobileAppService, { manifest, 1 })
runner.Step("RAI App 2", common.registerAppWOPTU, { 2 })
runner.Step("Publish MEDIA AppService", common.publishMobileAppService, { manifest2, 2 })
runner.Step("RAI App 3", common.registerAppWOPTU, { 3 })
runner.Step("Activate App", common.activateApp, { 3 })   

runner.Title("Test")    
runner.Step("RPCPassThroughTest_MultipleAS", RPCPassThruTest)   

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
