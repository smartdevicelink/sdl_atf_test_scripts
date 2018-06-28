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
-- 2) RC app1 is registered
-- 3) Non-RC app2 is registered
-- 4) RC app registers
-- SDL must:
-- 1) send an OnRCStatus notification to the newly registered RC app (allowed=true, allocatedModules=[], freeModules=[x,y,z])
-- 2) not send an OnRCStatus notification to the HMI
-- 3) not send OnRCStatus notifications to the already registered RC apps
-- 4) not send OnRCStatus notifications to the already registered non-RC apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

-- [[ Local Functions]]
local function registerRCapp()
	common.registerRCApplication(2)
	common.getMobileSession(1):ExpectNotification("OnRCStatus")
	:Times(0)
	common.getMobileSession(3):ExpectNotification("OnRCStatus")
	:Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RC app1 registration", common.registerRCApplication, { 1 })
runner.Step("Non-RC app2 registration", common.registerNonRCApp, { 3 })
runner.Step("RC app3 registration", registerRCapp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
