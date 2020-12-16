---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 and app2 are registered on SDL.
--  2) AppServiceProvider permissions (with NAVIGATION AppService permissions to handle rpc GetWayPoints) are assigned for <app1ID>
--  3) GetWayPoints permissions are assigned for <app2ID>
--  4) app1 is activated and sends a PublishAppService request (with {serviceType=NAVIGATION, handledRPC=GetWayPoints} in the manifest)
--
--  Steps:
--  1) app2 sends a GetWayPoints request to core
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
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "NAVIGATION",
  handledRPCs = {45},    
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  navigationServiceManifest = {acceptsWayPoints = true}
}

local rpcRequest = {
  name = "GetWayPoints",
  hmi_name = "Navigation.GetWayPoints", 
  params = {
    wayPointType = "ALL"
  },
  hmi_params = {
    wayPointType = "ALL"
  }
}

local rpcResponse = { 
  params = {
    success = true,
    resultCode = "SUCCESS",
    wayPoints = {
      { 
        coordinate = {
          longitudeDegrees = 50,
          latitudeDegrees = 50
        },
        locationName = "Location 1",
        addressLines = {
          "Line 1",
          "Line 2",
          "Line 3",
          "Line 4"
        }
      },
      { 
        coordinate = {
          longitudeDegrees = 40,
          latitudeDegrees = 40
        },
        locationName = "Location 2",
        addressLines = {
          "Line 5",
          "Line 6",
          "Line 7",
          "Line 8"
        }
      }
    },
    info = "Request was handled by app services"
  }    
}

--[[ Local functions ]]
local function PTUfunc(tbl)
  -- Add permissions for app1
  local pt_entry = common.getAppServiceProducerConfig(1)
  pt_entry.app_services.NAVIGATION = { handled_rpcs = {{function_id = 45}} }
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
  -- Add permissions for app2
  pt_entry = common.getAppDataForPTU(2)
  pt_entry.groups = { "Base-4" , "WayPoints" }
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = pt_entry
end

local function RPCPassThruTest()
  local providerMobileSession = common.getMobileSession(1)
  local mobileSession = common.getMobileSession(2)
  
  local cid = mobileSession:SendRPC(rpcRequest.name, rpcRequest.params)
      
  providerMobileSession:ExpectRequest(rpcRequest.name, rpcRequest.params):Do(function(_, data)
      providerMobileSession:SendResponse(rpcRequest.name, data.rpcCorrelationId, rpcResponse.params)
  end)

  -- Core will NOT handle the RPC  
  EXPECT_HMICALL(rpcRequest.hmi_name, rpcRequest.hmi_params):Times(0)

  mobileSession:ExpectResponse(cid, rpcResponse.params)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)    
runner.Step("RAI App 1", common.registerApp)
runner.Step("Activate App 1", common.activateApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("PublishAppService", common.publishMobileAppService, { manifest, 1 })
runner.Step("RAI App 2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })   

runner.Title("Test")    
runner.Step("GetWayPoints_RPCPassThrough_SUCCESS", RPCPassThruTest)   

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
