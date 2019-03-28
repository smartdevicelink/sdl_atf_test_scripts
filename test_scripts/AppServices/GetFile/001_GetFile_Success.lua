---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) AppServiceConsumer permissions are assigned for <appID>
--  3) Application sends a PutFile Request with a given file name
--
--  Steps:
--  1) Application sends a GetFile Request with the same file name
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
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Putfile", common.putFileInStorage, {1, putFileParams, result})

runner.Title("Test")
runner.Step("Getfile", common.getFileFromStorage, {1, getFileParams, result})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

