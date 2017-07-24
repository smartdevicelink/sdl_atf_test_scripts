---------------------------------------------------------------------------------------------------
-- RPC: SetInteriorVehicleData
-- Script: 009
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function setVehicleData(pModuleType, self)
	local moduleData = commonRC.getModuleControlData(pModuleType)
	moduleData.fakeParam = 123
	self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = moduleData
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = self.applications["Test Application"],
		moduleData = commonRC.getModuleControlData(pModuleType)
	})
	:ValidIf(function(_, data)
			if data.params.moduleData.fakeParam then
				return false, 'Fake parameter is not cut-off ("fakeParam":' .. tostring(data.params.moduleData.fakeParam) .. ")"
			end
			return true
		end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("SetInteriorVehicleData " .. mod, setVehicleData, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
