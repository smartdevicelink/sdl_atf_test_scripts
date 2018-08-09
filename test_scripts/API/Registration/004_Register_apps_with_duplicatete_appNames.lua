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
-- 1) The second mobile app tries to register with the same name as the first mobile app.
-- SDL does:
-- 1) Does not registered the second mobile app and returnes DUPLICATE_NAME response to the second mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function duplicateAppName(pAppId)
    if not pAppId then pAppId = 2 end
    common.getMobileSession(pAppId):StartService(7)
    :Do(function()
        local CorIdRegister = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface",
        {
            syncMsgVersion = {
            majorVersion = 3,
            minorVersion = 0 },
            appName = "Test Application",
            isMediaApplication = true,
            languageDesired = 'EN-US',
            hmiDisplayLanguageDesired = 'EN-US',
            appID = "2"
        })
        common.getMobileSession(pAppId):ExpectResponse(CorIdRegister, { success = false, resultCode = "DUPLICATE_NAME" })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("Second app with a duplicate appName same as appName for the first app", duplicateAppName)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
