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
-- 1) When two applications are registered with one appID.
-- SDL does:
-- 1) Sends APPLICATION_REGISTERED_ALREADY code when the app sends RegisterAppInterface within the same connection
--    after RegisterAppInterface has been already sent and not unregistered yet.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local params = {
    syncMsgVersion = { majorVersion = 3, minorVersion = 0 },
    appName = "SyncProxyTester",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appID = "1"
}

--[[ Local Functions ]]
local function rai_withOneAppID()
        local CorIdRegister = common.getMobileSession():SendRPC("RegisterAppInterface", params)
        common.getMobileSession():ExpectResponse(CorIdRegister, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register app", common.registerApp)

runner.Title("Test")
runner.Step("Register_applications_with_one_appID", rai_withOneAppID)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
