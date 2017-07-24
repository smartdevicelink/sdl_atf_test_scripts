---------------------------------------------------------------------------------------------------
-- RPC: SetInteriorVehicleData
-- Description
-- In case:
-- application sends valid SetInteriorVehicleData with just read-only parameters in "climateControlData" struct, for muduleType: CLIMATE,
-- SDL must
-- respond with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local module_data_climate = {
	moduleType = "CLIMATE",
	climateControlData = {
		currentTemperature = {
			unit = "CELSIUS",
			value = 21.5
		}
	}
}

--[[ Local Functions ]]
local function setVehicleData(module_data, self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {moduleData = module_data})

	EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)

	self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "READ_ONLY" })
	commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test: SDL respond with READ_ONLY if SetInteriorVehicleData is sent with read_only params")
runner.Step("Send SetInteriorVehicleData with currentTemperature only", setVehicleData, { module_data_climate })
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
