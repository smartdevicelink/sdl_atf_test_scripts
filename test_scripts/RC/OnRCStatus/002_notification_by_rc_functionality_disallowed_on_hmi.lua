---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall not send OnRCStatus notifications to all registered mobile applications and the HMI
-- in case RC functionality is disallowed on HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonOnRCStatus = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function RCdiallowedFromHMI()
	commonOnRCStatus.getHMIconnection():SendNotification("RC.OnRemoteControlSettings", { allowed = false })
end

local function RegistrationWithoutRCNotification()
	commonOnRCStatus.rai_ptu_n()
	commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus")
		:Times(0)
	EXPECT_HMINOTIFICATION("RC.OnRCStatus")
		:Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)
runner.Step("RC functionality is disallowed from HMI", RCdiallowedFromHMI)

runner.Title("Test")
runner.Step("RC appregistration without OnRCStatus notification", RegistrationWithoutRCNotification)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
