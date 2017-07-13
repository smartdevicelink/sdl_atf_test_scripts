---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 005
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function step1(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDecription =	{ -- invalid name of parameter
			moduleType = "CLIMATE",
			moduleName = "Module Climate"
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function step2(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDscription =	{ -- invalid name of parameter
			moduleType = "RADIO",
			moduleName = "Module Radio"
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function step3(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "CLIMATE",
			moduleName = "Module Climate"
		},
		subscribe = 17 -- invalid type of parameter
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function step4(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "RADIO",
			moduleName = "Module Radio"
		},
		subscribe = 21 -- invalid type of parameter
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function step5(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			-- moduleType = "CLIMATE", --  mandatory parameter absent
			moduleName = "Module Climate"
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function step6(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			-- moduleType = "RADIO",   --  mandatory parameter absent
			moduleName = "Module Radio"
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {})
	:Times(0)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

local function step7(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "CLIMATE",
			moduleName = "Module Climate",
			fakeParam = 7
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
				isSubscribed = true
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
				isSubscribed = true,
				moduleData = {
					moduleType = "CLIMATE",
					moduleName = "Module Climate",
					climateControlData = commonRC.getClimateControlData()
				}
			})
end

local function step8(self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "RADIO",
			moduleName = "Module Radio",
			fakeParam = 7
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
					radioControlData = commonRC.getRadioControlData()
				}
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
			isSubscribed = true,
			moduleData = {
				moduleType = "RADIO",
				moduleName = "Module Radio",
				radioControlData = commonRC.getRadioControlData()
			}
		})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE (invalid name of parameter)", step1)
runner.Step("GetInteriorVehicleData_RADIO (invalid name of parameter)", step2)
runner.Step("GetInteriorVehicleData_CLIMATE (invalid type of parameter)", step3)
runner.Step("GetInteriorVehicleData_RADIO (invalid type of parameter)", step4)
runner.Step("GetInteriorVehicleData_CLIMATE (mandatory parameter absent)", step5)
runner.Step("GetInteriorVehicleData_RADIO (mandatory parameter absent)", step6)
runner.Step("GetInteriorVehicleData_CLIMATE (fake parameter)", step7)
runner.Step("GetInteriorVehicleData_RADIO (fake parameter)", step8)
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
