---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall not send OnRCStatus notifications to not rc registered app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonOnRCStatus = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function PTUfunc(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  commonOnRCStatus.AddOnRCStatusToPT(tbl)
  tbl.policy_table.app_policies[appId] = commonOnRCStatus.getRCAppConfig()
  tbl.policy_table.app_policies[appId].AppHMIType = { "DEFAULT" }
end

local function RegistrationNotRCapp()
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

runner.Title("Test")
runner.Step("Registration of not rc application", RegistrationNotRCapp, { PTUfunc })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
