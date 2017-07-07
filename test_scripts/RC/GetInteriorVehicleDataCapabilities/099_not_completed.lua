---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleDataCapabilities
-- Script: 099
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function step(id, module_types, self)
	local session = commonRC.getMobileSession(self, id)

	local cid = session:SendRPC("GetInteriorVehicleDataCapabilities", {
			moduleTypes = module_types
		})

	EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities", {
			appID = self.applications[config["application" .. id].registerAppInterfaceParams.appID],
			moduleTypes = module_types
		})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
					interiorVehicleDataCapabilities = commonRC.getInteriorVehicleDataCapabilities(module_types)
				})
	end)

	session:ExpectResponse(cid, {
			success = true,
			resultCode = "SUCCESS",
			interiorVehicleDataCapabilities = commonRC.getInteriorVehicleDataCapabilities(module_types)
		})
end

local function ptu_update_func(tbl)
	tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = { "RADIO", "CLIMATE" },
      groups = { "Base-4" },
      groups_primaryRC = { "Base-4", "RemoteControl" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("RAI2", commonRC.rai_n, { 2 })
runner.Title("Test")
runner.Step("GetInteriorVehicleDataCapabilities_CLIMATE_App1", step, { 1, { "CLIMATE" } })
runner.Step("GetInteriorVehicleDataCapabilities_CLIMATE_App2", step, { 2, { "CLIMATE" } })
runner.Step("GetInteriorVehicleDataCapabilities_RADIO_App1", step, { 1, { "RADIO" } })
runner.Step("GetInteriorVehicleDataCapabilities_RADIO_App2", step, { 2, { "RADIO" } })
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
