---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application 1 with <appID> is registered on SDL.
--  2) Application 2 with <appID> is registered on SDL.
--  3) AppServiceProvider permissions for App 1 are assigned for <appID> with PublishAppService
--  4) AppServiceProvider permissions for App 2 are assigned for <appID> with PublishAppService
--  5) Application 1 sends a PublishAppService RPC request with serviceType MEDIA
--  6) Application 2 sends a PublishAppService RPC request with serviceType MEDIA
--
--  Steps:
--  1) HMI sends AppService.AppServiceActivation activate = true, App 2's serviceID, setAsDefault = true
--  2) Disconnect App 2
--  3) Stop Core
--  4) Follow preconditions
--
--  Expected:
--  1) HMI receives a successful response with activate = true, setAsDefault = true
--  2) Both mobile apps and the HMI receieve an OnSystemCapabilityUpdated notification. App 1 is DEACTIVATED. App 2 is ACTIVATED.
--  3) OnDisconnect expect App1 and HMI to receive OnSystemCapabilityUpdated App 2 updateReason REMOVED. App1 record is unchanged.
--  4) PublishAppService for App 2 after restart, expect OnSystemCapabilityUpdated PUBLISHED for App 2
--  5) PublishAppService for App 2 after restart, expect OnSystemCapabilityUpdated ACTIVATED for App 2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local manifest2 = {
  serviceName = config.application2.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application2.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local rpc = {
  name = "AppService.AppServiceActivation",
  params = {
    activate = true,
    setAsDefault = true
  }
}

local expectedResponse = {
  result = {
    activate = true,
    setAsDefault = true
  },
  code = 0,
  method = "AppService.AppServiceActivation"
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
  tbl.policy_table.app_policies[common.getConfigAppParams(2).fullAppID] = common.getAppServiceProducerConfig(2);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession(1)
  local mobileSession2 = common.getMobileSession(2)
  local service_id = common.getAppServiceID(2)
  local requestParams = rpc.params
  requestParams.serviceID = service_id

  local cid = common.getHMIConnection():SendRequest(rpc.name, requestParams)  

  EXPECT_HMIRESPONSE(cid, expectedResponse):Times(1)

  local onSystemCapabilityParams1 = common.appServiceCapabilityUpdateParams("DEACTIVATED", manifest)
  local onSystemCapabilityParams2 = common.appServiceCapabilityUpdateParams("ACTIVATED", manifest2)

  local combinedParams = onSystemCapabilityParams1
  combinedParams.systemCapability.appServicesCapabilities.appServices[2] = onSystemCapabilityParams2.systemCapability.appServicesCapabilities.appServices[1]

  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", combinedParams):Times(AtLeast(1))
  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", combinedParams):Times(AtLeast(1))
  mobileSession2:ExpectNotification("OnSystemCapabilityUpdated", combinedParams):Times(AtLeast(1))
end

local function disconnectDefaultService(self)
  local mobileSession = common.getMobileSession(2)
  local cid = mobileSession:SendRPC("UnregisterAppInterface", {})
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

  local onSystemCapabilityParams1 = common.appServiceCapabilityUpdateParams("DEACTIVATED", manifest)
  local onSystemCapabilityParams2 = common.appServiceCapabilityUpdateParams("REMOVED", manifest2)

  local combinedParams = onSystemCapabilityParams1
  combinedParams.systemCapability.appServicesCapabilities.appServices[2] = onSystemCapabilityParams2.systemCapability.appServicesCapabilities.appServices[1]
  combinedParams.systemCapability.appServicesCapabilities.appServices[1].updateReason = nil
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSystemCapabilityUpdated", combinedParams):Times(1)
  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", combinedParams):Times(1)

end

local function republishDefaultApp(self)
  local mobileSession = common.getMobileSession(2)
  local cid = mobileSession:SendRPC("PublishAppService", {
    appServiceManifest = manifest2
  })
  local onSystemCapabilityParams = common.appServiceCapabilityUpdateParams("ACTIVATED", manifest)
  local onSystemCapabilityParams1 = common.appServiceCapabilityUpdateParams("DEACTIVATED", manifest)

  local onSystemCapabilityParams2 = common.appServiceCapabilityUpdateParams("PUBLISHED", manifest2)
  local onSystemCapabilityParams3 = common.appServiceCapabilityUpdateParams("ACTIVATED", manifest2)

  local publishedParams = onSystemCapabilityParams
  publishedParams.systemCapability.appServicesCapabilities.appServices[2] = onSystemCapabilityParams2.systemCapability.appServicesCapabilities.appServices[1]
  publishedParams.systemCapability.appServicesCapabilities.appServices[1].updateReason = nil

  local activatedParams = onSystemCapabilityParams1
  activatedParams.systemCapability.appServicesCapabilities.appServices[2] = onSystemCapabilityParams3.systemCapability.appServicesCapabilities.appServices[1]
  activatedParams.systemCapability.appServicesCapabilities.appServices[1].updateReason = nil

  mobileSession:ExpectNotification("OnSystemCapabilityUpdated", publishedParams, activatedParams):Times((2))

  mobileSession:ExpectResponse(cid, {
    appServiceRecord = {
      serviceManifest = manifest2,
      servicePublished = true
    },
    success = true,
    resultCode = "SUCCESS"
  }):Times(1)
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
runner.Step("Publish App Service 2", common.publishSecondMobileAppService, { manifest, manifest2, 2 })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_SUCCESS", processRPCSuccess)
runner.Step("Disconnect Default Service App", disconnectDefaultService)
runner.Step("Clean sessions", common.cleanSession, {1})
runner.Step("Clean sessions", common.cleanSession, {2})
runner.Step("Stop SDL", common.postconditions)
runner.Step("Clean environment", commonFunctions.SDLForceStop)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 1 })
runner.Step("Activate App", common.activateApp)
runner.Step("RAI w/o PTU", common.registerAppWOPTU, { 2 })
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })
runner.Step("Reconnect Default Service App", republishDefaultApp)


runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

