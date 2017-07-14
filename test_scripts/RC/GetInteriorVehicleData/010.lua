---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 010
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function step(module_type, self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = module_type
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = module_type
		},
		subscribe = true
	})
   :Do(function(_, data)
			self.hmiConnection:SendError(data.id, data.method, "READ_ONLY", "Read only parameters received")
		end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE_READ_ONLY", step, {"CLIMATE"})
runner.Step("GetInteriorVehicleData_RADIO_READ_ONLY", step, {"RADIO"})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
