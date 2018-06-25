---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC functionality is allowed on HMI
-- 2) RC application is registered
-- 3) RC functionality is disallowed on HMI
-- SDL must:
-- 1) Send OnRCStatus notification with allowed = false to registered mobile application and
-- not send to the HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function disableRCFromHMI()
  common.getHMIconnection():SendNotification("RC.OnRemoteControlSettings", { allowed = false })
  common.getMobileSession():ExpectNotification("OnRCStatus",
	{ allowed = false, freeModules = {}, allocatedModules = {} })
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("OnRCStatus notification by app registration", common.registerRCApplication, { 1 , true })

runner.Title("Test")
runner.Step("RC functionality is disallowed from HMI", disableRCFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
