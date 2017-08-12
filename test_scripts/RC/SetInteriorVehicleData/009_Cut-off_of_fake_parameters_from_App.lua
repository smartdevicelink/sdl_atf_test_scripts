---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) Mobile app send SetInteriorVehicleData with moduleType that matches with controlData structure
-- 2) and control data structure has fake parameters (in this case related to another module or unknown)
-- SDL must:
-- 1) Cut off these parameters and forward to HMI only parameters of controlData that are related to requested moduleType
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function setVehicleData(pModuleType, self)
	local moduleData = commonRC.getSettableModuleControlData(pModuleType)
	moduleData.fakeParam = 123
	self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = moduleData
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = self.applications["Test Application"],
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
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
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("SetInteriorVehicleData " .. mod, setVehicleData, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
