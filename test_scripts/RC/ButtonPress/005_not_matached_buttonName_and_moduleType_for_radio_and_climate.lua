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
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')


--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("ButtonPress",	{
		moduleType = "CLIMATE",
		buttonName = "VOLUME_UP",
		buttonPressMode = "SHORT"
	})

	EXPECT_HMICALL("Buttons.ButtonPress")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

local function step2(self)
	local cid = self.mobileSession:SendRPC("ButtonPress",	{
		moduleType = "RADIO",
		buttonName = "AC",
		buttonPressMode = "LONG"
	})

	EXPECT_HMICALL("Buttons.ButtonPress")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("ButtonPress_CLIMATE", step1)
runner.Step("ButtonPress_RADIO", step2)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
