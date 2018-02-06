---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall send OnRCStatus notifications to all registered mobile applications and the HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonOnRCStatus = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Modules = {
  "CLIMATE",
  "RADIO",
  "AUDIO",
  "LIGHT",
  "HMI_SETTINGS",
  "SEAT"
}

local NotifParams = {freeModules = commonOnRCStatus.ModulesArray(Modules), allocatedModules = { }}

--[[ Local Functions ]]
local function RegisterSeconApp()
	commonOnRCStatus.rai_n_rc_app(2)
	commonOnRCStatus.getMobileSession(2):ExpectNotification("OnRCStatus", NotifParams)
	commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", NotifParams)
  NotifParams.appID = commonOnRCStatus.getHMIAppId()
	EXPECT_HMINOTIFICATION("RC.OnRCStatus", NotifParams )
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)

runner.Title("Test")
runner.Step("OnRCStatus notification by app registration", commonOnRCStatus.RegisterRCapplication,
  { NotifParams })
runner.Step("OnRCStatus notification by registration second app", RegisterSeconApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
