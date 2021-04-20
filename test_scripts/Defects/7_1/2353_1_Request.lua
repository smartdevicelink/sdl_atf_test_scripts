---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2353
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to proceed with request from HMI after cut off of fake parameters
-- Scenario: request that SDL should transfer to mobile app
--
-- Steps:
-- 1. HMI sends request with fake parameter
-- SDL does:
--  - cut off fake parameters
--  - check whether request is valid
--  - proceed with request in case if it's valid and transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local manifest = {
  serviceName = common.getConfigAppParams().appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = common.getConfigAppParams().syncMsgVersion,
  mediaServiceManifest = {}
}

--[[ Local Functions ]]
local function ptUpdate(tbl)
  tbl.policy_table.app_policies[common.getConfigAppParams().fullAppID] = common.getAppServiceProducerConfig(1);
end

local function sendPerformAppServiceInteraction()
  local hmiReq = {
    serviceUri = "mobile:sample.service.uri",
    serviceID = common.getAppServiceID(),
    fakeParam = "123"
  }
  local mobReq = {
    originApp = common.sdl.getSDLIniParameter("HMIOriginID"),
    serviceID = hmiReq.serviceID,
    serviceUri = hmiReq.serviceUri
  }
  local mobRes = {
    serviceSpecificResult = "SPECIFIC_RESULT",
    success = true,
    resultCode = "SUCCESS"
  }
  local hmiRes = {
    result = {
      code = 0, -- SUCCESS
      method = "AppService.PerformAppServiceInteraction",
      serviceSpecificResult = mobRes.serviceSpecificResult
    }
  }
  local cid = common.getHMIConnection():SendRequest("AppService.PerformAppServiceInteraction", hmiReq)
  common.getMobileSession():ExpectRequest("PerformAppServiceInteraction", mobReq)
  :Do(function(_, data)
      common.getMobileSession():SendResponse(data.rpcFunctionId, data.rpcCorrelationId, mobRes)
    end)
  :ValidIf(function(_, data)
    if data.payload.fakeParam then
      return false, "Unexpected 'fakeParam' is received"
    end
    return  true
  end)
  common.getHMIConnection():ExpectResponse(cid, hmiRes)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)
runner.Step("Publish App Service", common.publishMobileAppService, { manifest })

runner.Title("Test")
runner.Step("HMI sends PerformAppServiceInteraction", sendPerformAppServiceInteraction)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
