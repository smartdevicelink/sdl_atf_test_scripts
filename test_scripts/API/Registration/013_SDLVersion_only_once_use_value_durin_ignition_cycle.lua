---------------------------------------------------------------------------------------------------
-- Regression check
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- Check that SDL returns SDL version in RegisterAppInterface response.
-- In case:
-- 1) Update into .ini file param "SDLVersion".
-- 2) SDL, HMI are started.
-- 3) Mobile application is registered with updated "SDLVersion".
-- SDL does:
-- 1) Not send and return SDL version in RegisterAppInterface response.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local sdlVersionsParams = "SDL_4"

local valueForResponse = {
    sdlVersion =  sdlVersionsParams
}

--[[ Local Functions ]]
local function updateINIFile()
    common.backupINIFile()
    commonFunctions:write_parameter_to_smart_device_link_ini("SDLVersion", sdlVersionsParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Title("Test")
runner.Step("Update .ini file", updateINIFile)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("sdlVersion in RAI response", common.registerApp, { 1, common.getRequestParams(1), _, valueForResponse } )

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore .ini file", common.restoreINIFile)
