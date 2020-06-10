---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: OnVehicleData notification with StabilityControlsStatus and
--   "parameters" field is omitted at PolicyTable for this notification
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed, "parameters" field is omitted at PolicyTable for OnVehicleData notification
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus and gps parameters
--
-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus and gps
--    SDL sends OnVehicleData notification with received from HMI gps data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local vehicle_data_items = { "gps", "stabilityControlsStatus" }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "Emergency-1" }
  local grp = pTbl.policy_table.functional_groupings["Emergency-1"]
  grp.rpcs.SubscribeVehicleData.parameters = vehicle_data_items
  grp.rpcs.OnVehicleData.parameters = nil
  pTbl.policy_table.vehicle_data = nil
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App1", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptUpdate })
common.Step("Activate App1", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus and other parameters", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", vehicle_data_items })

common.Title("Test")
common.Step("Expect OnVehicleData with StabilityControlsStatus and other parameters",
  common.checkNotificationSuccess, { vehicle_data_items })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
