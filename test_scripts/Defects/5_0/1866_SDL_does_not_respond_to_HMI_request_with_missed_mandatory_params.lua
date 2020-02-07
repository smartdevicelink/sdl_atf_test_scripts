---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1866
--
-- Precondition:
-- 1) Core, HMI started.
-- 2) App is registered on HMI.
-- Description:
-- SDL does not respond to HMI request with missed mandatory params
-- Steps to reproduce:
-- 1) HMI sends SDL.GetUserFriendlyMessage request with missed mandatory parameter messageCodes.
-- Expected result:
-- SDL responds with code INVALID_DATA to HMI.
-- Actual result:
-- SDL does not send response to HMI.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Functions ]]
local function GetUserFriendlyMessage(self)
	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US"})
	EXPECT_HMIRESPONSE(RequestId,{result = {code = 11, data = {method = "SDL.GetUserFriendlyMessage"}}})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu)

runner.Title("Test")
runner.Step("GetUserFriendlyMessage request with missed mandatory parameter messageCodes", GetUserFriendlyMessage)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
