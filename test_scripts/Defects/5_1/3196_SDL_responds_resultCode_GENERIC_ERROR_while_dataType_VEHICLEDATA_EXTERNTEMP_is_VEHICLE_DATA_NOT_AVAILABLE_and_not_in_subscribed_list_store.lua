---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/3196
--
-- Description:
-- SDL responds "resultCode: SUCCESS" while dataType:VEHICLEDATA_EXTERNTEMP is VEHICLE_DATA_NOT_AVAILABLE and not
-- in-subscribed list store
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) SubscribeVehicleData (speed, externalTemperature), OnVehicleData is allowed by policy for app_1 and app_2.
-- 3) Navi App1 and navi app2 are registered and activated.
-- Steps to reproduce:
-- 1) Send SubscribeVehicleData (speed, externalTemperature) from app_1 => SDL responds SubscribeVehicleData
-- SDL should send "SUCCESS, (speed: SUCCESS), (externalTemperature: VEHICLE_DATA_NOT_AVAILABLE)" to mobile app1.
-- 2) Send SubscribeVehicleData (speed, externalTemperature) from app_2.
-- 3) Observe the result.
-- Expected result:
-- SDL should send "SUCCESS, (speed: SUCCESS), (externalTemperature: VEHICLE_DATA_NOT_AVAILABLE)" to mobile app2.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

config.application1.appHMIType = { "NAVIGATION" }
config.application2.appHMIType = { "NAVIGATION" }

--[[ Local Functions ]]
local function ptuUpdate(tbl)
  local VDgroup = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" },
        parameters = {"speed", "externalTemperature"}
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "NewTestCaseGroup"}
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "NewTestCaseGroup"}
end

local function subscribeVehicleData(pAppId, pFirstApp)
  local cid = common.getMobileSession(pAppId):SendRPC("SubscribeVehicleData", { speed = true, externalTemperature = true })
  if pFirstApp then
    common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { speed = true, externalTemperature = true })
    :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        speed = { dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS" },
        externalTemperature = { dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "VEHICLE_DATA_NOT_AVAILABLE" }
      })
    end)
  else
    common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { externalTemperature = true })
    :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        externalTemperature = { dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "VEHICLE_DATA_NOT_AVAILABLE" }
      })
    end)
  end
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    speed = { dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS" },
    externalTemperature = { dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "VEHICLE_DATA_NOT_AVAILABLE" }
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 is registered", common.registerAppWOPTU)
runner.Step("Activate App1", common.activateApp)
runner.Step("App2 is registered", common.registerApp, {2})
runner.Step("Activate App2", common.activateApp, {2})
runner.Step("Perform PTU", common.policyTableUpdate,{ptuUpdate})

runner.Title("Test")
runner.Step("App1 is subscribed to get speed and externalTemperature data", subscribeVehicleData, {1, true})
runner.Step("App2 is subscribed to get speed and externalTemperature data", subscribeVehicleData, {2, false})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
