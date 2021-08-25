---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3368
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL rejects empty structs sent by HMI for vehicle data parameter
--
-- Steps:
-- 1. App subscribed to vehicle data updates
-- 2. App sends GetVehicleData request to SDL for vehicle data parameter
-- SDL does:
--  - resend request to HMI
-- 3. HMI sends empty struct for vehicle data parameter in:
--  - GetVehicleData response
--  - OnVehicleData notification
-- SDL does:
--  - treat GetVehicleData response from HMI as invalid and respond with 'GENERIC_ERROR' to the mobile app
--  - ignore OnVehicleData notification from HMI and does not resend it to the mobile app
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
    pTbl.policy_table.functional_groupings["Location-1"].rpcs[rpc].parameters = { "fuelRange" }
  end
end

--[[ Local Functions ]]
local function getVD()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { fuelRange = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { fuelRange = { { } } })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function subscribeVD()
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", { fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { fuelRange = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { fuelRange = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_FUELRANGE" } })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function onVD()
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { fuelRange = { { } } })
  common.getMobileSession():ExpectNotification("OnVehicleData")
  :Times(0)
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
