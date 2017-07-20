---------------------------------------------------------------------------------------------------
-- RPC: SetInteriorVehicleData
-- Script: 010
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

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
			local moduleData = commonRC.getModuleControlData(pModuleType)
			moduleData.fakeParam = 123
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = moduleData
			})
		end)

	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf(function(_, data)
			if data.payload.moduleData.fakeParam then
				return false, 'Fake parameter is not cut-off ("fakeParam":' .. tostring(data.payload.moduleData.fakeParam) .. ")"
			end
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
