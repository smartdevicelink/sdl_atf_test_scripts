---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/9
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/button_press_emulation.md
-- Item: Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [SDL_RC] Button press event emulation
--
-- Description:
-- In case:
-- 1) Application registered with REMOTE_CONTROL AppHMIType sends ButtonPress RPC
-- 2) (with <climate-related-buttons> and RADIO moduleType) OR (with <radio-related-buttons> and CLIMATE moduleType)
-- SDL must:
-- 1) Respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local paramsStep1 = {
	moduleType = "CLIMATE",
	buttonName = "VOLUME_UP",
	buttonPressMode = "SHORT"
}
local paramsStep2 = {
	moduleType = "RADIO",
	buttonName = "AC",
	buttonPressMode = "LONG"
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("ButtonPress_CLIMATE", commonRC.rpcDeniedWithCustomParams, {paramsStep1, 1, "ButtonPress", "INVALID_DATA"})
runner.Step("ButtonPress_RADIO", commonRC.rpcDeniedWithCustomParams, {paramsStep2, 1, "ButtonPress", "INVALID_DATA"})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
