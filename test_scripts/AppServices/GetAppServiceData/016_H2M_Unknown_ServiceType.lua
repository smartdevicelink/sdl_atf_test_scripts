---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with GetAppServiceData
--  3) Application has published a MEDIA service
--
--  Steps:
--  1) HMI sends a AppService.GetAppServiceData RPC request with serviceType MUSIC
--
--  Expected:
--  1) SDL responds to the HMI with {code = "DATA_NOT_AVAILABLE"}
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

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

local rpc = {
  name = "GetAppServiceData",
  hmiName = "AppService.GetAppServiceData",
  params = {
    serviceType = "MUSIC"
  }
}

local expectedResponse = {
  serviceData = nil,
  success = false,
  resultCode = "DATA_NOT_AVAILABLE"
}

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceProducerConfig(1);
end

--[[ Local Functions ]]
local function processRPCSuccess(self)
  local mobileSession = common.getMobileSession()
  local cid = common.getHMIConnection():SendRequest(rpc.hmiName, rpc.params)

  -- Request is NOT forwarded to ASP
  mobileSession:ExpectRequest(rpc.name, rpc.params):Times(0)

  EXPECT_HMIRESPONSE(cid, {
    error = {
      serviceData = nil, 
      code = 9, --DATA_NOT_AVAILABLE (HMI_API)
      data = { 
        method = rpc.hmiName 
      }
    }
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_DATA_NOT_AVAILABLE", processRPCSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
