---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0105-remote-control-seat.md 
-- User story: 
-- Use case: 
-- Item
--
-- Description:
-- In case:
-- 1) application sends valid SetInteriorVehicleData with just read-only parameters in "seatControlData" struct for muduleType: SEAT --Changed
-- SDL must
-- respond with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setVehicleData(module_data)
	local mobSession = commonRC.getMobileSession()
	local cid = mobileSession:SendRPC("SetInteriorVehicleData", {moduleData = module_data})

	EXPECT_HMICALL("RC.SetInteriorVehicleData"):Times(0)

	mobileSession:ExpectResponse(cid, { success = false, resultCode = "READ_ONLY" })
	commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test: SDL respond with READ_ONLY if SetInteriorVehicleData is sent with read_only params")

for parameter_name, parameter_value in pairs(module_data_seat.seatControlData) do 
	local seat_read_only_parameters = {
		moduleType = module_data_seat.moduleType,
		seatControlData = {[parameter_name] = parameter_value}
	}
	runner.Step(
		"Send SetInteriorVehicleData with " .. tostring(parameter_name) .." only",
		setVehicleData,
		{seat_read_only_parameters})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)