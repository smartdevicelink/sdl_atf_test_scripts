---------------------------------------------------------------------------------------------------
--  Precondition: 
--
--  Steps:
--  1) HMI sends a PublishAppService RPC request
--
--  Expected:
--  1) SDL sends a OnSystemCapabilityUpdated(APP_SERVICES, PUBLISHED) notification to HMI
--  2) SDL sends a OnSystemCapabilityUpdated(APP_SERVICES, ACTIVATED) notification to HMI
--  3) SDL responds to HMI with "resultCode: SUCCESS, success: true"
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

local rpc = {
  name = "AppService.PublishAppService",
  params = {
    appServiceManifest = manifest
  }
}

local expectedResponse = {
  result = {
    appServiceRecord = {
      serviceManifest = manifest,
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
    common.appServiceCapabilityUpdateParams("PUBLISHED", manifest),
    common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)):Times(2)
  EXPECT_HMIRESPONSE(cid, expectedResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

