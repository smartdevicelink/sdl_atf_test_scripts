---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/9
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/button_press_emulation.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Button press event emulation
--
-- Description:
-- In case:
-- 1) Application is registered with REMOTE_CONTROL appHMIType
-- 2) and sends valid ButtonPress RPC with valid parameters
-- SDL must:
-- 1) Transfer this request to HMI
-- 2) Respond with <result_code> received from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsStep1 = {
	moduleType = "CLIMATE",
	buttonName = "AC",
	buttonPressMode = "SHORT"
}
local paramsStep2 = {
	moduleType = "RADIO",
	buttonName = "VOLUME_UP",
	buttonPressMode = "LONG"
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("ButtonPress_CLIMATE", commonRC.rpcButtonPress, { paramsStep1, 1})
runner.Step("ButtonPress_RADIO", commonRC.rpcButtonPress, { paramsStep2, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
