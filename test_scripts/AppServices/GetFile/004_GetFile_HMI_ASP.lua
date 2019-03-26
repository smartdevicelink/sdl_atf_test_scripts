---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) AppServiceConsumer permissions are assigned for <appID>
--  3) HMI sends a PublishAppService
--
--  Steps:
--  1) Application sends a GetFile Request with the id of the service published by the HMI
--
--  Expected:
--  1) GetFile will return SUCCESS
--  2) The CRC value returned in the GetFile response will be the same as the crc32 hash of the file binary data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local functions ]]
local function PTUfunc(tbl)
    tbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID] = common.getAppServiceConsumerConfig(1);
end

--[[ Local variables ]]
local manifest = {
  serviceName = config.application1.registerAppInterfaceParams.appName,
  serviceType = "MEDIA",
  allowAppConsumers = true,
  rpcSpecVersion = config.application1.registerAppInterfaceParams.syncMsgVersion,
  mediaServiceManifest = {}
}

local putFileParams = {
  syncFileName = "icon.png",
  fileType ="GRAPHIC_PNG",
}

local getFileParams = {
  fileName = "icon.png",
  fileType = "GRAPHIC_PNG",
}

local result = { success = true, resultCode = "SUCCESS"}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("PublishAppService", common.publishEmbeddedAppService, { manifest })
runner.Step("RAI App 1", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Getfile", common.getFileFromService, {1, 0, getFileParams, result})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

