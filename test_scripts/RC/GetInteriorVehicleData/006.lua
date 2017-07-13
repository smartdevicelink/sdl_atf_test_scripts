---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 006
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "CLIMATE",
			moduleName = "Module Climate"
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = "CLIMATE",
			moduleName = "Module Climate"
		},
		subscribe = true
	})
  	:Do(function(_, _)
		-- HMI does not respond
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

	commonTestCases:DelayedExp(11000)
end

local function step2(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "RADIO",
			moduleName = "Module Radio"
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = "RADIO",
			moduleName = "Module Radio"
		},
		subscribe = true
	})
  	:Do(function(_, _)
  		-- HMI does not respond
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

	commonTestCases:DelayedExp(11000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE (HMI does not respond)", step1)
runner.Step("GetInteriorVehicleData_RADIO (HMI does not respond)", step2)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
