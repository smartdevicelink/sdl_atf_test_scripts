---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 006
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

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
  	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = {
					moduleType = "CLIMATE",
					moduleName = "Module Climate",
					climateControlData = commonRC.getClimateControlData()
				},
				isSubscribed = "yes" -- invalid type of parameter
			})
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
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
  	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				isSubscribed = "yes", -- invalid type of parameter
				moduleData = {
					moduleType = "RADIO",
					moduleName = "Module Radio",
					radioControlData = commonRC.getRadioControlData()
				}
			})
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
end

local function step3(self)
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
  	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = {
					moduleType = "CLIMATE",
					moduleName = "Module Climate",
					-- climateControlData = commonRC.getClimateControlData() -- missing mandatory parameter
				},
				isSubscribed = true
			})
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
end

local function step4(self)
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
  	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				isSubscribed = true,
				moduleData = {
					moduleType = "RADIO",
					moduleName = "Module Radio",
					-- radioControlData = commonRC.getRadioControlData() -- missing mandatory parameter
				}
			})
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE (Invalid response from HMI-Invalid type of parameter)", step1)
runner.Step("GetInteriorVehicleData_RADIO (Invalid response from HMI-Invalid type of parameter)", step2)
runner.Step("GetInteriorVehicleData_CLIMATE (Invalid response from HMI-Missing mandatory parameter)", step3)
runner.Step("GetInteriorVehicleData_RADIO (Invalid response from HMI-Missing mandatory parameter)", step4)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
