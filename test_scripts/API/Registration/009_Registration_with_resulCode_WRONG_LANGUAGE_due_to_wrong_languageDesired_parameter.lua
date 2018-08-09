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
-- 1) Mobile application is registered with wrong "languageDesired" parameter.
-- SDL does:
-- 1) Send the WRONG_LANGUAGE response result code to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local firstWrongLang = {
    syncMsgVersion = {
    majorVersion = 3,
    minorVersion = 0 },
    appName = "SyncProxyTester",
    isMediaApplication = true,
    appID = "1",
    languageDesired = "DE-DE",
    hmiDisplayLanguageDesired = "EN-US"
}

local secondWrongLang = {
    syncMsgVersion = {
    majorVersion = 3,
    minorVersion = 0 },
    appName = "SyncProxyTester",
    isMediaApplication = true,
    appID = "1",
    languageDesired = "EN-US",
    hmiDisplayLanguageDesired = "DE-DE"
}

--[[ Local Functions ]]
local function rai_languageDesiredWrong(params)
    common.getMobileSession():StartService(7)
    :Do(function()
        local CorIdRegister = common.getMobileSession():SendRPC("RegisterAppInterface",params)
        common.getHMIConnection("BasicCommunication.OnAppRegistered",
        {
            appName = "SyncProxyTester",
            isMediaApplication = true,
            hmiDisplayLanguageDesired = 'EN-US',
            appID = "1"
        })
        common.getMobileSession():ExpectResponse(CorIdRegister, { success = true, resultCode = "WRONG_LANGUAGE" })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("RAI_with_wrong_languageDesired_parameter", rai_languageDesiredWrong, { firstWrongLang })
runner.Step("Application unregistered", common.unregisterAppInterface)
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("RAI_with_wrong_languageDesired_parameter", rai_languageDesiredWrong, { secondWrongLang })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
