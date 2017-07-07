---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
-- Script: 001
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function step1_1(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
			moduleDescription =	{
				moduleType = "CLIMATE",
				moduleZone = commonRC.getInteriorZone()
			},
			subscribe = false
		})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
			appID = self.applications["Test Application"],
			moduleDescription =	{
				moduleType = "CLIMATE",
				moduleZone = commonRC.getInteriorZone()
			},
			subscribe = false
		})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
					isSubscribed = false,
					moduleData = {
						moduleType = "CLIMATE",
						moduleZone = commonRC.getInteriorZone(),
						climateControlData = commonRC.getClimateControlData()
					}
				})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = false })
end

local function step1_2(self)
	self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
			moduleData = {
	      moduleType = "RADIO",
	      moduleZone = commonRC.getInteriorZone(),
	      climateControlData = commonRC.getRadioControlData()
	    }
	  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData")
  :Times(0)

  commonTestCases:DelayedExp(commonRC.timeout)
end

local function step2_1(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
			moduleDescription =	{
				moduleType = "RADIO",
				moduleZone = commonRC.getInteriorZone()
			},
			subscribe = false
		})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
			appID = self.applications["Test Application"],
			moduleDescription =	{
				moduleType = "RADIO",
				moduleZone = commonRC.getInteriorZone()
			},
			subscribe = false
		})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
					isSubscribed = false,
					moduleData = {
						moduleType = "RADIO",
						moduleZone = commonRC.getInteriorZone(),
						radioControlData = commonRC.getRadioControlData()
					}
				})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = false })
end

local function step2_2(self)
 	self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
			moduleData = {
	      moduleType = "CLIMATE",
	      moduleZone = commonRC.getInteriorZone(),
	      radioControlData = commonRC.getClimateControlData()
	    }
	  })

  EXPECT_NOTIFICATION("OnInteriorVehicleData")
  :Times(0)

  commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE", step1_1)
runner.Step("OnInteriorVehicleData_CLIMATE", step1_2)
runner.Step("GetInteriorVehicleData_RADIO", step2_1)
runner.Step("OnInteriorVehicleData_RADIO", step2_2)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
