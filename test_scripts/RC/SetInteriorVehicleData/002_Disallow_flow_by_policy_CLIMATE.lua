---------------------------------------------------------------------------------------------------
-- Description
-- In case:
-- 1) "moduleType" in app's assigned policies has one or more valid values
-- 2) and SDL received SetInteriorVehicleData request from App with moduleType not in list
-- SDL must:
-- 1) Disallow app's remote-control RPCs for this module (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local mod = "CLIMATE"

--[[ Local Functions ]]
local function setVehicleData(pModuleType, self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = commonRC.getModuleControlData(pModuleType)
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

local function ptu_update_func(tbl)
	tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = { "RADIO" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })

runner.Title("Test")
runner.Step("SetInteriorVehicleData " .. mod, setVehicleData, { mod })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
