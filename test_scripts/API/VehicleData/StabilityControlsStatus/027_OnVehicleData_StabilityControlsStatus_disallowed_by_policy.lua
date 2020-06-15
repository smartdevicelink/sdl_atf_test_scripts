---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: OnVehicleData notification with StabilityControlsStatus parameter is NOT allowed by Policies
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed, StabilityControlsStatus is NOT allowed by Policies for OnVehicleData notification
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus parameter
--
-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus
--    SDL doesn't send OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "Emergency-1" }
  local grp = pTbl.policy_table.functional_groupings["Emergency-1"]
  grp.rpcs.SubscribeVehicleData.parameters = {
    "stabilityControlsStatus",
    "gps"
  }
  grp.rpcs.OnVehicleData.parameters = {
    "gps"
  }
  pTbl.policy_table.vehicle_data = nil
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App1", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptUpdate })
common.Step("Activate App1", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus VehicleData", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "stabilityControlsStatus", "gps" }})

common.Title("Test")
common.Step("Ignore OnVehicleData with StabilityControlsStatus", common.checkNotificationIgnored,
  {{ "stabilityControlsStatus" }})

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
