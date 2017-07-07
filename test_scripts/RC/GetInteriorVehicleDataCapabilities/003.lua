---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleDataCapabilities
-- Script: 003
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function step(module_types, self)
	self, module_types = commonRC.getSelfAndParams(module_types, self)

	local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities", {
			moduleTypes = module_types
		})

	EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities", {
			appID = self.applications["Test Application"],
			moduleTypes = { "RADIO" }
		})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
					interiorVehicleDataCapabilities = commonRC.getInteriorVehicleDataCapabilities({ "RADIO" })
				})
	end)

	EXPECT_RESPONSE(cid, {
			success = true,
			resultCode = "SUCCESS",
			interiorVehicleDataCapabilities = commonRC.getInteriorVehicleDataCapabilities({ "RADIO" })
		})
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
runner.Step("GetInteriorVehicleDataCapabilities_RADIO_both", step, { { "CLIMATE", "RADIO" } })
runner.Step("GetInteriorVehicleDataCapabilities_RADIO_absent", step, { nil })
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
