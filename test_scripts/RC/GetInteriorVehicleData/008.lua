---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 001
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local json = require('modules/json')

--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "CLIMATE"
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = "CLIMATE"
		},
		subscribe = true
	})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = {
					moduleType = "CLIMATE",
					climateControlData = commonRC.getClimateControlData()
				},
				isSubscribed = true
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
				isSubscribed = true,
				moduleData = {
					moduleType = "CLIMATE",
					climateControlData = commonRC.getClimateControlData()
				}
			})
end

local function step2(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "RADIO"
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = "RADIO"
		},
		subscribe = true
	})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				isSubscribed = true,
				moduleData = {
					moduleType = "RADIO",
					radioControlData = commonRC.getRadioControlData()
				}
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
			isSubscribed = true,
			moduleData = {
				moduleType = "RADIO",
				radioControlData = commonRC.getRadioControlData()
			}
		})
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
runner.Step("GetInteriorVehicleData_CLIMATE", step1)
runner.Step("GetInteriorVehicleData_RADIO", step2)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
