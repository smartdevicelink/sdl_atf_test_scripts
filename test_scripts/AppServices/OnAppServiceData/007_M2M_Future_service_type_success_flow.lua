---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application 1 with <appID> is registered on SDL.
--  2) Application 2 with <appID2> is registered on SDL.
--  3) Specific permissions are assigned for <appID> with PublishAppService
--  4) Specific permissions are assigned for <appID2> with OnAppServiceData
--  5) Application 1 has published a FUTURE service
--  6) Application 2 is subscribed to FUTURE app service data
--
--  Steps:
--  2) Application 1 sends a OnAppServiceData RPC notification with serviceType FUTURE
--
--  Expected:
--  1) SDL forwards the OnAppServiceData notification to Application 2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.ValidateSchema = false

--[[ Local Variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "FUTURE",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local rpc = {
  name = "OnAppServiceData"
}

local expectedNotification = {
  serviceData = {
    serviceType = manifest.serviceType,
    futureServiceData = {
      futureParam1 = "Value",
      futureParam2 = 4,
      futureParam3 = {
        futureParam4 = 7.8
      }
    }
  }
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1, manifest.serviceType);
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = common.getAppServiceConsumerConfig(2);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession(1)
  local mobileSession2 = common.getMobileSession(2)
  local service_id = common.getAppServiceID()
  local notificationParams = expectedNotification
  notificationParams.serviceData.serviceID = service_id

  mobileSession:SendNotification(rpc.name, notificationParams)
  mobileSession2:ExpectNotification(rpc.name, notificationParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 2 })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })
runner.Step("Subscribe App Service Data", common.mobileSubscribeAppServiceData, { 1, manifest.serviceType, 2 })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

