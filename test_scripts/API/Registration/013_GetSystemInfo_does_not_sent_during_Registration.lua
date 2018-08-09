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
-- 1) Check that SDL returns SDL version in RegisterAppInterface response
-- SDL does:
-- 1) Does not send GetSystemInfo during register mobile application and returns SDL version in RegisterAppInterface response.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local sdlVersionsParams = {
    string = "SDL_4",
    lowerBound = "v",
    outLowerBound = "",
    upperBound = "1234567890!@#$%^&*()_+{}:|<>?[];'\\,./qwertyuiopASDFGHJKLzxcvbnm1234567890!@#$%^&*()_+{}:|<>?[];'\\,./",
    onlyDigits = "123456"
}

local function updateINIFile(pVercions)
    common.backupINIFile()
    commonFunctions:write_parameter_to_smart_device_link_ini("SDLVersion", pVercions)
end

local function sdlVersionInRAIResponse(pSDLvercions)
    common.getMobileSession():StartService(7)
    :Do(function()
        local CorIdRegister = common.getMobileSession():SendRPC("RegisterAppInterface",
        {
            syncMsgVersion = {
            majorVersion = 3,
            minorVersion = 0 },
            appName = "TestApplication",
            isMediaApplication = true,
            languageDesired = 'EN-US',
            hmiDisplayLanguageDesired = 'EN-US',
            appID = "1"
        })
        EXPECT_HMICALL("BasicCommunication.GetSystemInfo")
        :Times(0)
        common.getMobileSession():ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS", sdlVersion = pSDLvercions })
    end)
end

--[[ Scenario ]]
for k, v in pairs (sdlVersionsParams) do
    runner.Title("Preconditions")
    runner.Step("Clean environment", common.preconditions)

    runner.Title("Test")
    runner.Step("Update .ini file", updateINIFile, { v })
    runner.Step("Start SDL, init HMI, connect Mobile", common.start)
    runner.Step("systemSoftwareVersion" .. k, sdlVersionInRAIResponse, { v })
    runner.Step("Application unregistered", common.unregisterAppInterface)
    runner.Step("Clean sessions", common.cleanSessions)

    runner.Title("Postconditions")
    runner.Step("Stop SDL", common.postconditions)
end
