---------------------------------------------------------------------------------------------------
-- Regression check
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
-- 1) Not send and return SDL version in RegisterAppInterface response.
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

--[[ Scenario ]]
for k, v in pairs (sdlVersionsParams) do
    runner.Title("Preconditions")
    runner.Step("Clean environment", common.preconditions)

    runner.Title("Test")
    runner.Step("Update .ini file", updateINIFile, { v })
    runner.Step("Start SDL, init HMI, connect Mobile", common.start)
    runner.Step("systemSoftwareVersion " .. k, common.registerApp, { pAppId, pParam, presultParam, v })
    runner.Step("Application unregistered", common.unregisterAppInterface)
    runner.Step("Clean sessions", common.cleanSessions)

    runner.Title("Postconditions")
    runner.Step("Stop SDL", common.postconditions)
    runner.Step("Restore PreloadedPT", common.restorePreloadedPT)
end
