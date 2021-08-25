---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3368
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL cuts off empty structs sent by HMI for vehicle data parameter
--
-- Steps:
-- 1. App subscribed to vehicle data updates
-- 2. App sends GetVehicleData request to SDL for a few vehicle data parameters
-- SDL does:
--  - resend request to HMI
-- 3. HMI sends empty struct for one vehicle data parameter and valid data for the rest in:
--  - GetVehicleData response
--  - OnVehicleData notification
-- SDL does:
--  - for GetVehicleData response:
--    - cut off vehicle data parameter with empty struct from HMI response
--    - respond to the mobile app with 'WARNINGS' with the rest of parameters with valid data
--  - for OnVehicleData notification
--    - cut off vehicle data parameter with empty struct from HMI response
--    - respond to the mobile app with the rest of parameters with valid data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.app.getParams().fullAppID].groups = { "Base-4", "Location-1" }
  pTbl.policy_table.functional_groupings["Location-1"].user_consent_prompt = nil
  for rpc in pairs(pTbl.policy_table.functional_groupings["Location-1"].rpcs) do
    pTbl.policy_table.functional_groupings["Location-1"].rpcs[rpc].parameters = { "speed", "fuelRange" }
  end
end

--[[ Local Functions ]]
local function getVD()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { speed = true, fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { speed = true, fuelRange = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { speed = 1.23, fuelRange = { { } } })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS", speed = 1.23 })
  :ValidIf(function(_, data)
      if data.payload.fuelRange then
        return false, "Unexpected parameter 'fuelRange' received"
      end
      return true
    end)
end

local function subscribeVD()
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", { speed = true, fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { speed = true, fuelRange = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { fuelRange = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_FUELRANGE" },
          speed = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED" } })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function onVD()
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { speed = 4.56, fuelRange = { { } } })
  common.getMobileSession():ExpectNotification("OnVehicleData", { speed = 4.56 })
  :ValidIf(function(_, data)
      if data.payload.fuelRange then
        return false, "Unexpected parameter 'fuelRange' received"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)
runner.Step("App subscribes to VD", subscribeVD)

runner.Title("Test")
runner.Step("App sends GetVehicleData", getVD)
runner.Step("HMI sends OnVehicleData", onVD)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
