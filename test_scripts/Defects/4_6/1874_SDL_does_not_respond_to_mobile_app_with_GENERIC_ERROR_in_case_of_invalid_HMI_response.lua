---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1874
--
-- Precondition:
-- 1) Core, HMI started.
-- 2) App is registered on HMI.
-- 3) App is activated
-- Description:
-- SDL does not respond to mobile app with GENERIC_ERROR and correct info string in case of invalid HMI response
-- Steps to reproduce:
-- 1) App sends GetVehicleData request with correct parameters.
-- 2) HMI sends invalid response
--    Invalid response means:
--	  	a. params out of bounds
--	  	b. mandatory params are missing
--	  	c. params of wrong type
-- Expected:
-- SDL send response to mobile app with {"resultCode":"GENERIC_ERROR","success":false,"info":"Invalid message received from vehicle"} .
-- Actual result
-- SDL send response to mobile app with {"resultCode":"INVALID_DATA","success":false,"info":"Received invalid data on HMI response"} .
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

-- [[ Local Variables]]
local function pTUpdateFunc(tbl)
  table.insert(tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups, "DrivingCharacteristics-3")
end

-- [[ Local Functions ]]
local function missingMandatoryParam(self)
	local cid = self.mobileSession1:SendRPC("GetVehicleData", {steeringWheelAngle = true, myKey = true} )
	EXPECT_HMICALL("VehicleInfo.GetVehicleData", {steeringWheelAngle = true, myKey = true})
	:Do(function(_, data)
		self.hmiConnection:SendResponse(data.id, "VehicleInfo.GetVehicleData", "SUCCESS",
		{ steeringWheelAngle  = 2000, myKey = { fakeValue = "NO_DATA_EXISTS" }} )
	end)
	self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end

local function paramsOutOfBounds(self)
	local cid = self.mobileSession1:SendRPC("GetVehicleData", {steeringWheelAngle = true, myKey = true} )
	EXPECT_HMICALL("VehicleInfo.GetVehicleData", {steeringWheelAngle = true, myKey = true})
	:Do(function(_, data)
		self.hmiConnection:SendResponse(data.id, "VehicleInfo.GetVehicleData", "SUCCESS",
		{steeringWheelAngle = 2001, myKey = { e911Override = "NO_DATA_EXISTS" }} )
	end)
	self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end

local function wrongTypeParams(self)
	local cid = self.mobileSession1:SendRPC("GetVehicleData", {steeringWheelAngle = true, myKey = true} )
	EXPECT_HMICALL("VehicleInfo.GetVehicleData", {steeringWheelAngle = true, myKey = true})
	:Do(function(_, data)
		self.hmiConnection:SendResponse(data.id, "VehicleInfo.GetVehicleData", "SUCCESS",
		{steeringWheelAngle = "10", myKey = { e911Override = "NO_DATA_EXISTS" }} )
	end)
	self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration, PTU", common.rai_ptu, {pTUpdateFunc})
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("GetVehicleData response with mandatory params are missing", missingMandatoryParam)
runner.Step("GetVehicleData response with params out of bounds", paramsOutOfBounds)
runner.Step("GetVehicleData response with params of wrong type", wrongTypeParams)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
