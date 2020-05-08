---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 is Registered
--  2) AppServiceProvider permissions are assigned for <app1ID>
--
--  Steps:
--  1) app1 sends a PublishAppService (with {serviceType="MEDIA", handledRPC=ButtonPress})
--  2) HMI sends a GetAppServiceRecords to Core
--
--  Expected:
--  1) Core returns the service record of the MEDIA service published by app1 ({servicePublished=true, serviceActive=true}) 
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
  handledRPCs = { 41 },    
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local function getExpectedResponse()
  local response = {
    code = 0,
    method = "AppService.GetAppServiceRecords",
    serviceRecords = {
      {
        servicePublished = true,
        serviceActive = true,
        serviceID = common.getAppServiceID(1),
        serviceManifest = manifest
      }
    }
  }
  return response
end

--[[ Local functions ]]
local function PTUfunc(tbl)
  local pt_entry = common.getAppServiceProducerConfig(1)
  pt_entry.app_services.MEDIA.handled_rpcs = {{function_id = 41}}
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = pt_entry
end

local function getAppServiceRecords(service_type)
  expectedResponse = getExpectedResponse()
  table.sort(expectedResponse.serviceRecords, function(r1, r2) return r1.serviceID < r2.serviceID end)
  local rid = common.getHMIConnection():SendRequest(expectedResponse.method, {
    serviceType = service_type
  })
  EXPECT_HMIRESPONSE(rid, expectedResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI App 1", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("GetAppServiceRecords_MOBILE")    
runner.Step("Publish Mobile AppService", common.publishMobileAppService, { manifest, 1 })
runner.Step("GetAppServiceRecords", getAppServiceRecords, { "MEDIA" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
