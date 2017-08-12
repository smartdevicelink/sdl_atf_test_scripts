---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Button press event emulation
--
-- Description:
-- In case:
-- 1) Non remote-control application is registered on SDL
-- 2) and SDL received ButtonPress request from this App
-- SDL must:
-- 1) Disallow remote-control RPCs for this app (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("ButtonPress",	{
		moduleType = "CLIMATE",
		buttonName = "AC",
		buttonPressMode = "SHORT"
	})

	EXPECT_HMICALL("Buttons.ButtonPress")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

local function step2(self)
	local cid = self.mobileSession:SendRPC("ButtonPress",	{
		moduleType = "RADIO",
		buttonName = "VOLUME_UP",
		buttonPressMode = "LONG"
	})

	EXPECT_HMICALL("Buttons.ButtonPress")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

local function ptu_update_func(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId].moduleType = nil
  tbl.policy_table.app_policies[appId].groups_primaryRC = nil
  tbl.policy_table.app_policies[appId].AppHMIType = { "DEFAULT" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("ButtonPress_CLIMATE", step1)
runner.Step("ButtonPress_RADIO", step2)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
