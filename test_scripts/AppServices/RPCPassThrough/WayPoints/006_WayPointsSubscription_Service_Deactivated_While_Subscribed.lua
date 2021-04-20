---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 and app2 are registered on SDL.
--  2) AppServiceProvider permissions (with NAVIGATION AppService permissions to handle rpc GetWayPoints) are assigned for <app1ID>
--  3) WayPoints permissions are assigned for <app1ID>, <app2ID>
--  4) app1 is activated and sends a PublishAppService request (with {serviceType=NAVIGATION, handledRPC=GetWayPoints} in the manifest)
--
--  SubscribeWayPoints
--
--  Steps:
--  1) app2 sends a SubscribeWayPoints request to Core, HMI receives Navigation.SubscribeWayPoints request
--  and responds with SUCCESS
--  2) app1 sends OnWayPointChange notification to Core
--  3) HMI sends Navigation.OnWayPointChange notification to Core
--
--  Expected:
--  1) Core does not forward OnWayPointChange from app1 to app2
--  2) Core forwards OnWayPointChange from HMI to app2
--
--  Deactivate App Service
--
--  Steps:
--  1) HMI sends AppServiceActivation request with activate=false to deactivate app1's NAVIGATION service
--  2) app1 sends OnWayPointChange notification to Core
--  3) HMI sends Navigation.OnWayPointChange notification to Core
--
--  Expected:
--  1) Core does not forward OnWayPointChange from app1 to app2
--  2) Core forwards OnWayPointChange from HMI to app2
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

local subscribeResponse = { 
  params = {
    success = true,
    resultCode = "SUCCESS"
  }
}

local unsubscribeRequest = {
  name = "UnsubscribeWayPoints",
  hmi_name = "Navigation.UnsubscribeWayPoints", 
  params = {},
  hmi_params = nil
}

local unsubscribeResponse = { 
  params = {
    success = true,
    resultCode = "SUCCESS"
  }
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
end

local function SubscribeWayPoints()
  local providerMobileSession = common.getMobileSession(1)
  local mobileSession = common.getMobileSession(2)
  
  local cid = mobileSession:SendRPC(subscribeRequest.name, subscribeRequest.params)

  -- App will NOT handle the RPC (but the subscription will still apply to the app service)
  providerMobileSession:ExpectRequest(subscribeRequest.name, subscribeRequest.params):Times(0)
 
  common.getHMIConnection():ExpectRequest(subscribeRequest.hmi_name, subscribeRequest.hmi_params):Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  mobileSession:ExpectResponse(cid, subscribeResponse.params)
end

local function DeactivateService()
  local cid = common.getHMIConnection():SendRequest("AppService.AppServiceActivation", {
    activate = false,
    serviceID = common.getAppServiceID()
  })
  common.getHMIConnection():ExpectResponse(cid, {result = {code = 0, method = "AppService.AppServiceActivation"}})
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
runner.Step("SubscribeWayPoints SUCCESS", SubscribeWayPoints)
runner.Step("OnWayPointChange From Mobile SUCCESS", common.onWayPointChangeFromMobile, { notificationParams })
runner.Step("OnWayPointChange From HMI Ignored", common.onWayPointChangeFromHMI, { notificationParams, 0 })
runner.Step("Deactivate App Service", DeactivateService)
runner.Step("OnWayPointChange From Mobile Ignored", common.onWayPointChangeFromMobile, { notificationParams, 0 })
runner.Step("OnWayPointChange From HMI SUCCESS", common.onWayPointChangeFromHMI, { notificationParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
