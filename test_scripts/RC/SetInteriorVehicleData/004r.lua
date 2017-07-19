---------------------------------------------------------------------------------------------------
-- RPC: SetInteriorVehicleData
-- Script: 004r
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = {
			moduleType = "RADIO",
			climateControlData = commonRC.getClimateControlData()
		}
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

	commonTestCases:DelayedExp(commonRC.timeout)
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("SetInteriorVehicleData_RADIO_gets_INVALID_DATA", step1)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
