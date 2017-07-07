---------------------------------------------------------------------------------------------------
-- RPC: SetInteriorVehicleData
-- Script: 001
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = {
			moduleType = "CLIMATE",
			moduleZone = commonRC.getInteriorZone(),
			climateControlData = commonRC.getClimateControlData()
		}
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = self.applications["Test Application"],
		moduleData = {
			moduleType = "CLIMATE",
			moduleZone = commonRC.getInteriorZone(),
			climateControlData = commonRC.getClimateControlData()
		}
	})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = {
					moduleType = "CLIMATE",
					moduleZone = commonRC.getInteriorZone(),
					climateControlData = commonRC.getClimateControlData()
				}
			})
		end)

	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function step2(self)
	local cid = self.mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = {
			moduleType = "RADIO",
			moduleZone = commonRC.getInteriorZone(),
			radioControlData = commonRC.getRadioControlData()
		}
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = self.applications["Test Application"],
		moduleData = {
			moduleType = "RADIO",
			moduleZone = commonRC.getInteriorZone(),
			radioControlData = commonRC.getRadioControlData()
		}
	})
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = {
					moduleType = "RADIO",
					moduleZone = commonRC.getInteriorZone(),
					radioControlData = commonRC.getRadioControlData()
				}
			})
		end)

	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("SetInteriorVehicleData_CLIMATE", step1)
runner.Step("SetInteriorVehicleData_RADIO", step2)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
