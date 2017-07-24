---------------------------------------------------------------------------------------------------
-- Description
-- In case:
-- 1) SDL has sent SetInteriorVehicleData with one or more settable parameters in "moduleData" struct
-- 2) and HMI responds with "resultCode: READ_ONLY"
-- SDL must:
-- 1) Send "resultCode: READ_ONLY, success:false" to the related mobile application
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
			self.hmiConnection:SendError(data.id, data.method, "READ_ONLY", "Read only parameters received")
		end)

	self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "READ_ONLY" })
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
