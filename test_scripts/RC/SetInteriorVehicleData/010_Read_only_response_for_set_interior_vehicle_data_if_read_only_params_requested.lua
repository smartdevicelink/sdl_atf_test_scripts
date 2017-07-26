---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData Requirement
--
-- Description:
-- In case:
-- 1) application sends valid SetInteriorVehicleData with just read-only parameters in "climateControlData" struct for muduleType: CLIMATE,
-- OR
-- 2) application sends valid SetInteriorVehicleData with just read-only parameters in "radioControlData" struct for muduleType: RADIO
-- SDL must
-- respond with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local module_data_climate = commonRC.getReadOnlyParamsByModule("CLIMATE")
local module_data_radio = commonRC.getReadOnlyParamsByModule("RADIO")

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

for parameter_name, parameter_value in pairs(module_data_climate.climateControlData) do
	local climate_read_only_parameters = {
		moduleType = module_data_climate.moduleType,
		climateControlData = {[parameter_name] = parameter_value}
	}
	runner.Step(
		"Send SetInteriorVehicleData with " .. tostring(parameter_name) .." only",
		setVehicleData,
		{climate_read_only_parameters})
end

for parameter_name, parameter_value in pairs(module_data_radio.radioControlData) do
	local radio_read_only_parameters = {
		moduleType = module_data_radio.moduleType,
		radioControlData = {[parameter_name] = parameter_value}
	}
	runner.Step(
		"Send SetInteriorVehicleData with " .. tostring(parameter_name) .. " only",
		setVehicleData,
		{radio_read_only_parameters})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
