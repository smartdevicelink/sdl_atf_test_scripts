---------------------------------------------------------------------------------------------------
-- RPC: SetInteriorVehicleData
-- Script: 003
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = {
			moduleType = "CLIMATE",
			moduleZone = commonRC.getInteriorZone(),
			climateControlData = commonRC.getClimateControlData()
		}
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

local function step2(self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = {
			moduleType = "RADIO",
			moduleZone = commonRC.getInteriorZone(),
			radioControlData = commonRC.getRadioControlData()
		}
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData")
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

	commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("SetInteriorVehicleData_CLIMATE", step1)
runner.Step("SetInteriorVehicleData_RADIO", step2)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
