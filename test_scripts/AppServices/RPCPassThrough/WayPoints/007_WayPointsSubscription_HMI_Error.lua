---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 and app2 are registered on SDL.
--  2) AppServiceProvider permissions (with NAVIGATION AppService permissions to handle rpc GetWayPoints) are assigned for <app1ID>
--  3) WayPoints permissions are assigned for <app1ID>, <app2ID>, <app3ID>
--  4) app1 is activated and sends a PublishAppService request (with {serviceType=NAVIGATION, handledRPC=GetWayPoints} in the manifest)
--
--  Steps:
--  1) app2 sends a SubscribeWayPoints request to Core, HMI receives Navigation.SubscribeWayPoints request
--  and responds with GENERIC_ERROR
--  1) app3 sends a SubscribeWayPoints request to Core, HMI receives Navigation.SubscribeWayPoints request
--  and responds with SUCCESS
--  3) app1 sends OnWayPointChange notification to Core
--  4) HMI sends Navigation.OnWayPointChange notification to Core
--
--  Expected:
--  1) Core responds to app2's SubscribeWayPoints with WARNINGS
--  1) Core responds to app3's SubscribeWayPoints with SUCCESS
--  1) Core forwards OnWayPointChange from app1 to app2
--  2) Core does not forward OnWayPointChange from HMI to app2
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

local notificationParams = {
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
  }
}

local subscribeRequest = {
  name = "SubscribeWayPoints",
  hmi_name = "Navigation.SubscribeWayPoints", 
  params = {},
  hmi_params = nil
}

--[[ Local functions ]]
local function PTUfunc(tbl)
  -- Add permissions for app1
  local pt_entry = common.getAppServiceProducerConfig(1)
  pt_entry.app_services.NAVIGATION = { handled_rpcs = {{function_id = 45}} }
  pt_entry.groups[#pt_entry.groups + 1] = "WayPoints"
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
  -- Add permissions for app2
  pt_entry = common.getAppDataForPTU(2)
  pt_entry.groups = { "Base-4" , "WayPoints" }
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = pt_entry
  -- Add permissions for app3
  pt_entry = common.getAppDataForPTU(3)
  pt_entry.groups = { "Base-4" , "WayPoints" }
  tbl.policy_table.app_policies[common.getConfigAppParams(3).fullAppID] = pt_entry
end

local function SubscribeWayPointsError()
  local providerMobileSession = common.getMobileSession(1)
  local mobileSession = common.getMobileSession(2)
  
  local cid = mobileSession:SendRPC(subscribeRequest.name, subscribeRequest.params)

  -- App will NOT handle the RPC (but the subscription will still apply to the app service)
  providerMobileSession:ExpectRequest(subscribeRequest.name, subscribeRequest.params):Times(0)

  -- HMI requests fails for some internal reason
  common.getHMIConnection():ExpectRequest(subscribeRequest.hmi_name, subscribeRequest.hmi_params):Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "GENERIC_ERROR", {})
  end)

  mobileSession:ExpectResponse(cid, {
    success = true,
    resultCode = "WARNINGS"
  })
end

local function SubscribeWayPointsSuccess()
  local providerMobileSession = common.getMobileSession(1)
  local mobileSession = common.getMobileSession(3)
  
  local cid = mobileSession:SendRPC(subscribeRequest.name, subscribeRequest.params)

  -- App will NOT handle the RPC (but the subscription will still apply to the app service)
  providerMobileSession:ExpectRequest(subscribeRequest.name, subscribeRequest.params):Times(0)

  -- Core will resend the HMI request since the first request errored out
  common.getHMIConnection():ExpectRequest(subscribeRequest.hmi_name, subscribeRequest.hmi_params):Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  mobileSession:ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS"
  })
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
runner.Step("RAI App 3", common.registerAppWOPTU, { 3 })
runner.Step("Activate App 3", common.activateApp, { 3 }) 

runner.Title("Test")
runner.Step("SubscribeWayPoints App 2 HMI Error WARNINGS", SubscribeWayPointsError)
runner.Step("SubscribeWayPoints App 3 HMI SUCCESS", SubscribeWayPointsSuccess)
runner.Step("OnWayPointChange From Mobile SUCCESS", common.onWayPointChangeFromMobile, { notificationParams })
runner.Step("OnWayPointChange From HMI Ignored", common.onWayPointChangeFromHMI, { notificationParams, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
