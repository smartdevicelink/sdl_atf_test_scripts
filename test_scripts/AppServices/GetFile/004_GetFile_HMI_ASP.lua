---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> and <appID2> is registered on SDL.
--  2) AppServiceProvider permissions are assigned for <appID>
--  3) AppServiceConsumer permissions are assigned for <appID2>
--
--  Steps:
--  1) Application 1 sends a PutFile Request with a given file name
--  2) Application 1 sends a PublishAppService
--  2) Application 2 sends a GetFile Request with the same file name and the id of the service published by app1
--
--  Expected:
--  1) GetFile will return SUCESS
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

runner.Title("Test ASProvider")    
-- runner.Step("Putfile", common.putFileInStorage, {1, putFileParams, result})
runner.Step("PublishAppService", common.publishEmbeddedAppService, { manifest })

runner.Title("Test ASConsumer")    
runner.Step("RAI App 1", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Step("Getfile", common.getFileFromService, {1, 0, getFileParams, result})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

