---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1875
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) App is registered and activated.
-- Description:
-- SDL does not treat GetVehicleData_response as invalid and does not send GENERIC_ERROR
-- Steps to reproduce:
-- 1) HMI sends GetVehilceData_response with 'gpsData' (and/or 'beltStatus'/ 'deviceStatus'/ 'tireStatus') structure
-- and this structure has at least one parameter with invalid value.
-- Expected:
-- SDL treats GetVehicleData_response as invalid.
-- send GENERIC_ERROR, success:false, info: Invalid message received from vehicle.
-- Actual result
-- SDL does not send GENERIC_ERROR.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Local Variables ]]
local function pTUpdateFunc(tbl)
    local VDgroup = {
        rpcs = {
            GetVehicleData = {
                hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
                parameters = {"gps", "deviceStatus", "tirePressure", "beltStatus"}
            }
        }
    }
    tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups = {"Base-4", "NewTestCaseGroup"}
end

local beltStatusResponse = {
	driverBeltDeployed = "NO"
}

local DeviceStatusResponse = {
	voiceRecOn = true
}

local gpsDataResponse = {
	longitudeDegrees = 100
}

local tireStatusResponse = {
	pressureTelltale = "OFF"
}

local tireStatusTable = {}
for key, value in pairs (tireStatusResponse) do
	local Table = commonFunctions:cloneTable(tireStatusResponse)
	if type(value) == "string" then
		Table[key] = value .. "\t"
	else
		Table[key].status = Table[key].status .. "\t"
	end
	tireStatusTable[key] = Table
end

--[[ Local Functions ]]
local function CreationTblWithInvalidVAlues(tbl)
	local CreatedTbl = {}
	for key, value in pairs (tbl) do
		local Table = commonFunctions:cloneTable(tbl)
		if type(value) == "string" then
			Table[key] =  value .. "\t"
		elseif type(value) == "number" then
			Table[key] = value + 1000
		elseif
			type(value) == "boolean" then
			Table[key] = "boolean"
		end
		CreatedTbl[key] = Table
	end
	return CreatedTbl
end

local beltStatusTable = CreationTblWithInvalidVAlues(beltStatusResponse)
local deviceStatusTable = CreationTblWithInvalidVAlues(DeviceStatusResponse)
local gpsResponsesTable = CreationTblWithInvalidVAlues(gpsDataResponse)

local function GetVDError(requestParams, responseParams, self)
	local cid = self.mobileSession1:SendRPC("GetVehicleData", requestParams)
	EXPECT_HMICALL("VehicleInfo.GetVehicleData", requestParams)
	:Do(function(_, data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
		responseParams)
    end)
	self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR",
	info = "Invalid message received from vehicle" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu, {pTUpdateFunc})
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
for k,v in pairs(beltStatusTable) do
	runner.Step("GetVehicleData_beltStatus_" .. k, GetVDError, { { beltStatus = true }, { beltStatus = v } })
end

for k,v in pairs(deviceStatusTable) do
	runner.Step("GetVehicleData_deviceStatus_" .. k, GetVDError, { { deviceStatus = true }, { deviceStatus = v } })
end

for k,v in pairs(gpsResponsesTable) do
	runner.Step("GetVehicleData_gps_" .. k, GetVDError, { { gps = true }, { gps = v } })
end

for k,v in pairs(tireStatusTable) do
	runner.Step("GetVehicleData_tirePressure_" .. k, GetVDError, { { tirePressure = true }, { tirePressure = v } })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
