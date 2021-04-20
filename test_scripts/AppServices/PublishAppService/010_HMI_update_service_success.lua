---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) HMI sends a PublishAppService RPC request
--
--  Steps:
--  1) HMI sends a PublishAppService RPC request with "allowAppConsumers = false" to update the service record.
--
--  Expected:
--  1) SDL sends a OnSystemCapabilityUpdated(APP_SERVICES, MANIFEST_UPDATE) notification to HMI
--  2) SDL responds to HMI with "resultCode: SUCCESS, success: true"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local manifest = {
  serviceName = "Embedded Media Service",
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local manifestUpdate = {
  serviceName = "Embedded Media Service",
  serviceType = "MEDIA",
  allowAppConsumers = false,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local rpc = {
  name = "AppService.PublishAppService",
  params = {
    appServiceManifest = manifestUpdate
  }
}

local expectedResponse = {
  result = {
    appServiceRecord = {
      serviceManifest = manifestUpdate,
      servicePublished = true,
      serviceActive = true
    },
    code = 0, 
    method = "AppService.PublishAppService"
  }
}

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local cid = common.getHMIConnection():SendRequest(rpc.name, rpc.params)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", 
    common.appServiceCapabilityUpdateParams("MANIFEST_UPDATE", manifestUpdate)):Times(1)
  EXPECT_HMIRESPONSE(cid, expectedResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Publish App Service", common.publishEmbeddedAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

