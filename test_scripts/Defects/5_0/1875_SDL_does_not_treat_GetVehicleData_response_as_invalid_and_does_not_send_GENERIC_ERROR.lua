---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1875
--
-- Description:
-- SDL does not treat GetVehicleData_response as invalid and does not send GENERIC_ERROR
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) App is registered and activated.
-- Steps to reproduce:
-- 1) HMI sends GetVehilceData_response with 'gpsData' (and/or 'beltStatus'/ 'deviceStatus'/ 'tireStatus') structure
-- and this structure has at least one parameter with invalid value.
-- SDL does:
-- treat GetVehicleData_response as invalid.
-- send GENERIC_ERROR, success:false, info: Invalid message received from vehicle.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local utils = require('user_modules/utils')
local json = require("modules/json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local beltStatusResponse = { driverBeltDeployed = "NO" }

local DeviceStatusResponse = { voiceRecOn = true }

local gpsDataResponse = { longitudeDegrees = 100 }

local tireStatusResponse = { pressureTelltale = "OFF" }

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
local function updatePreloadedPT(pGroups, pAppId)
  local pt = common.sdl.getPreloadedPT()
  if not pGroups then
    pGroups = {
      rpcs = {
        GetVehicleData = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
          parameters = {"gps", "deviceStatus", "tirePressure", "beltStatus"}
        }
      }
    }
  end
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pt.policy_table.app_policies[common.app.getParams(pAppId).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[common.app.getParams(pAppId).fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  common.sdl.setPreloadedPT(pt)
end

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

local function GetVDError(requestParams, responseParams)
	local cid = common.getMobileSession():SendRPC("GetVehicleData", requestParams)
	EXPECT_HMICALL("VehicleInfo.GetVehicleData", requestParams)
	:Do(function(_, data)
		common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
		responseParams)
	end)
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR",
	info = "Invalid message received from vehicle" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update local PT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

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
