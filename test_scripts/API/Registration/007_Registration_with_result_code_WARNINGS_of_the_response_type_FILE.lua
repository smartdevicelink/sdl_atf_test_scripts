---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Mobile application is registered with ttsName: type = FILE
-- SDL does:
-- 1) Returned  WARNINGS response to the mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function rai_ttsNameType_FILE()
    common.getMobileSession():StartService(7)
    :Do(function()
        local CorIdRegister = common.getMobileSession():SendRPC("RegisterAppInterface",
        {
            syncMsgVersion = {
            majorVersion = 3,
            minorVersion = 0 },
            appName = "SyncProxyTester",
            isMediaApplication = true,
            languageDesired = 'EN-US',
            hmiDisplayLanguageDesired = 'EN-US',
            appID = "2",
            ttsName = {{ text = "4005", type = "FILE"}}
        })
        common.getMobileSession():ExpectResponse(CorIdRegister, { success = true, resultCode = "WARNINGS" })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("Register_App_with_type_FILE", rai_ttsNameType_FILE)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
