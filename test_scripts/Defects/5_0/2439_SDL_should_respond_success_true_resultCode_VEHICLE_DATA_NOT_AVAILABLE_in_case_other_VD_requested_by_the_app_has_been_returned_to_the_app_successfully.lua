---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2439
--
-- Precondition:
-- 1) SDL and HMI are running.
-- 2) AApplication is registered and activated.
-- Description:
-- Steps to reproduce:
-- 1) Send GetVehicleData with rpm = true and speed = true
-- 2) SDL sends to HMI VehicleInfo.GetVehicleData: "params":
--    {"rpm":true, "speed":true}
-- 3) Send HMI response with 1 VD: success, 1 VD: VEHICLE_DATA_NOT_AVAILABLE
-- Expected result:
-- 1) SDL sends to mobile response of GetVehicleData with
--    {"resultCode":"VEHICLE_DATA_NOT_AVAILABLE", "success":true, "speed":50.5}
-- Actual result: 
-- 1) SDL sends to mobile response of GetVehicleData with
--    {"resultCode":"VEHICLE_DATA_NOT_AVAILABLE","success":false, "speed":50.5}
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function pTUpdateFunc(tbl)
    local VDgroup = {
        rpcs = {
            GetVehicleData = {
                hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
                parameters = { "rpm", "speed" }    
            },
        }
    }
    tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups = {"Base-4", "NewTestCaseGroup"}
end

local function getVehicleData()
  local cid = common.getMobileSession():SendRPC("GetVehicleData",{ speed = true, rpm = true })
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", { speed = true, rpm = true })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "DATA_NOT_AVAILABLE", { speed = 50 })
  end)
  common.getMobileSession():ExpectResponse(cid, {success = true, resultCode = "VEHICLE_DATA_NOT_AVAILABLE", speed = 50 })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Update ptu", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sets GetVehicleData ", getVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
