---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleDataCapabilities
-- Script: 011
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function step(module_types, self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities", {
			moduleTypes = module_types
		})

	EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities", {
			appID = self.applications["Test Application"],
			moduleTypes = module_types
		})
	:Do(function()
			-- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
			-- 		interiorVehicleDataCapabilities = commonRC.getInteriorVehicleDataCapabilities(module_types)
			-- 	})
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })

	commonTestCases:DelayedExp(11000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleDataCapabilities_CLIMATE", step, { { "CLIMATE" } })
runner.Step("GetInteriorVehicleDataCapabilities_RADIO", step, { { "RADIO" } })
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
