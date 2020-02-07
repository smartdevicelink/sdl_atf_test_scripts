---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1867
--
-- Precondition:
-- 1) Core, HMI started.
-- 2) App is registered on HMI.
-- Description:
-- SDL does not respond to HMI request with wrong type of parameters.
-- Steps to reproduce:
-- 1) HMI sends SDL.GetUserFriendlyMessage request with wrong type(Integer) of parameter messageCodes.
-- Expected:
-- SDL responds with code INVALID_DATA to HMI.
-- Actual result
-- SDL does not send response to HMI.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

-- [[ Local Functions ]]
local function GetUserFriendlyMessage(self)
	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = 1} )
	EXPECT_HMIRESPONSE(RequestId,{result = {code = 11, data = {method = "SDL.GetUserFriendlyMessage"}}})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration, PTU", common.rai_ptu_n_without_OnPermissionsChange)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("SDL sends GetUserFriendlyMessage request with wrong type", GetUserFriendlyMessage)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
