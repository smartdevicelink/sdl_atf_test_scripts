---------------------------------------------------------------------------------------------------
-- RPC: SetInteriorVehicleData
-- Script: 007
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local json = require('modules/json')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function setVehicleData(pModuleType, self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = commonRC.getModuleControlData(pModuleType)
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = self.applications["Test Application"],
		moduleData = commonRC.getModuleControlData(pModuleType)
	})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = commonRC.getModuleControlData(pModuleType)
			})
		end)

	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = json.EMPTY_ARRAY
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("SetInteriorVehicleData " .. mod, setVehicleData, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
