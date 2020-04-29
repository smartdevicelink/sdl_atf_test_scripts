---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1868
--
-- Precondition:
-- 1) Core, HMI started.
-- 2) App is registered on HMI.
-- Description:
-- SDL does not respond to HMI request with empty string parameter.
-- Steps to reproduce:
-- 1) HMI sends SDL.GetUserFriendlyMessage request with empty string in messageCodes
-- Expected result:
-- SDL responds with code INVALID_DATA to HMI.
-- Actual result:
-- SDL does not send response to HMI.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function GetUserFriendlyMessage(self)
	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
		{language = "EN-US", messageCodes = {""} })
	EXPECT_HMIRESPONSE(RequestId,{result = {code = 11,  data = {method = "SDL.GetUserFriendlyMessage"}}})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu)

runner.Title("Test")
runner.Step("GetUserFriendlyMessage_request_with_empty_string_in_messageCodes", GetUserFriendlyMessage)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
