---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 and app2 are registered on SDL.
--  2) AppServiceProvider permissions(with MEDIA AppService permissions to handle rpc ButtonPress) are assigned for <app1ID>
--  3) RemoteControl permissions are NOT assigned for <app2ID>
--  4) app1 sends a PublishAppService (with {serviceType=MEDIA, handledRPC=ButtonPress} in the manifest)
--
--  Steps:
--  1) app2 sends a ButtonPress request to core
--
--  Expected:
--  1) Core responds to app2 with {success = false, resultCode = "DISALLOWED"}
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  handledRPCs = {41},    
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local successResponse = {
  success = true,
  resultCode = "SUCCESS",
  info = "Request was handled by app services"
}

local rpcRequest = {
  name = "ButtonPress",
  hmi_name = "Buttons.ButtonPress", 
  params = {
    moduleType = "RADIO",
    buttonName = "OK",
    buttonPressMode = "SHORT"
  },
  hmi_params = {
    moduleType = "RADIO",
    buttonName = "OK",
    buttonPressMode = "SHORT"
  }
}

local rpcResponse = { 
  params = {success = false, resultCode="DISALLOWED"}    
}

--[[ Local functions ]]
local function PTUfunc(tbl)
  --Add permissions for app1
  local pt_entry = common.getAppServiceProducerConfig(1)
  pt_entry.app_services.MEDIA.handled_rpcs = {{function_id = 41}}
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
end

local function RPCPassThruTest()
  local providerMobileSession = common.getMobileSession(1)
  local mobileSession = common.getMobileSession(2)
  
  local cid = mobileSession:SendRPC(rpcRequest.name, rpcRequest.params)
      
  --Provider will NOT be forwarded the request
  providerMobileSession:ExpectRequest(rpcRequest.name, rpcRequest.params):Times(0)

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
runner.Step("RPCPassThroughTest_DISALLOWED", RPCPassThruTest)   

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
