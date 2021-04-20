---------------------------------------------------------------------------------------------------
--  Precondition: 
--
--  Steps:
--  1) HMI sends a PublishAppService (with {serviceType="MEDIA", handledRPC=ButtonPress})
--  2) HMI sends a GetAppServiceRecords to Core
--
--  Expected:
--  1) Core returns the service record of the MEDIA service published by the HMI ({servicePublished=true, serviceActive=true}) 
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local manifest = {
  serviceName = "HMI MEDIA",
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
        serviceID = common.getAppServiceID(0),
        serviceManifest = manifest
      }
    }
  }
  return response
end

--[[ Local functions ]]
local function getAppServiceRecords(service_type)
  expectedResponse = getExpectedResponse()
  table.sort(expectedResponse.serviceRecords, function(r1, r2) return r1.serviceID < r2.serviceID end)
  local rid = common.getHMIConnection():SendRequest(expectedResponse.method, {
    serviceType =  service_type
  })
  EXPECT_HMIRESPONSE(rid, expectedResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("GetAppServiceRecords_EMBEDDED")    
runner.Step("Publish Embedded AppService", common.publishEmbeddedAppService, { manifest })
runner.Step("GetAppServiceRecords", getAppServiceRecords, { "MEDIA" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)