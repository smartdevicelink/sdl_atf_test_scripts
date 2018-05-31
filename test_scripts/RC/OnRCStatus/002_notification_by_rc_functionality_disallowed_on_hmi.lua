---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC functionality is disallowed on HMI
-- 2) RC application is registered
-- SDL must:
-- 1) Not send OnRCStatus notification to registered mobile application and the HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function disableRCFromHMI()
	common.getHMIconnection():SendNotification("RC.OnRemoteControlSettings", { allowed = false })
	common.wait(2000)
end

local function registerAppWithoutRCNotification()
	common.rai_n()
	common.getMobileSession():ExpectNotification("OnRCStatus")
	:Times(0)
	EXPECT_HMINOTIFICATION("RC.OnRCStatus")
	:Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RC functionality is disallowed from HMI", disableRCFromHMI)

runner.Title("Test")
runner.Step("Register RC application without OnRCStatus notification", registerAppWithoutRCNotification)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
