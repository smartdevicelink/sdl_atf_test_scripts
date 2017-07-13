---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 004
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function step1(pResultCode, self)
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
			self.hmiConnection:SendResponse(data.id, data.method, pResultCode, {
				moduleData = {
					moduleType = "CLIMATE",
					climateControlData = commonRC.getClimateControlData()
				}
				-- isSubscribed = true

			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = pResultCode,
				-- isSubscribed = true,
				moduleData = {
					moduleType = "CLIMATE",
					climateControlData = commonRC.getClimateControlData()
				}
			})
end

local function step2(pResultCode, self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = "RADIO",
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = "RADIO",
		},
		subscribe = true
	})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, pResultCode, {
				-- isSubscribed = true,
				moduleData = {
					moduleType = "RADIO",
					radioControlData = commonRC.getRadioControlData()
				}
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = pResultCode,
			-- isSubscribed = true,
			moduleData = {
				moduleType = "RADIO",
				radioControlData = commonRC.getRadioControlData()
			}
		})
end

local function step1err(pResultCode, self)
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
			self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
		end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = pResultCode})
end

local function step2err(pResultCode, self)
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
			self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
		end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = pResultCode })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE with WARNINGS resultCode", step1, {"WARNINGS"})
runner.Step("GetInteriorVehicleData_RADIO with WARNINGS resultCode", step2, {"WARNINGS"})
runner.Step("GetInteriorVehicleData_CLIMATE with GENERIC_ERROR resultCode", step1err, {"GENERIC_ERROR"})
runner.Step("GetInteriorVehicleData_RADIO with GENERIC_ERROR resultCode", step2err, {"GENERIC_ERROR"})
runner.Step("GetInteriorVehicleData_CLIMATE with INVALID_DATA resultCode", step1err, {"INVALID_DATA"})
runner.Step("GetInteriorVehicleData_RADIO with INVALID_DATA resultCode", step2err, {"INVALID_DATA"})
runner.Step("GetInteriorVehicleData_CLIMATE with OUT_OF_MEMORY resultCode", step1err, {"OUT_OF_MEMORY"})
runner.Step("GetInteriorVehicleData_RADIO with OUT_OF_MEMORY resultCode", step2err, {"OUT_OF_MEMORY"})
runner.Step("GetInteriorVehicleData_CLIMATE with REJECTED resultCode", step1err, {"REJECTED"})
runner.Step("GetInteriorVehicleData_RADIO with REJECTED resultCode", step2err, {"REJECTED"})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
