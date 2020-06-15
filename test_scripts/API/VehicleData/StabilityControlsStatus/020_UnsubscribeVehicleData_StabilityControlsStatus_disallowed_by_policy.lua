---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: UnsubscribeVehicleData RPC with the only parameter stabilityControlsStatus,
-- which is NOT allowed by Policies
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed, stabilityControlsStatus param is NOT allowed by Policies
-- 4) App is activated
--
-- Steps:
-- 1) App sends UnsubscribeVehicleData (with stabilityControlsStatus = true) request to SDL
--    SDL does not send VehicleInfo.UnsubscribeVehicleData request to HMI
--    SDL sends UnsubscribeVehicleData response with (success: false, resultCode: "DISALLOWED",
--      stabilityControlsStatus = {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_STABILITYCONTROLSSTATUS"}) to App
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
  grp.rpcs.UnsubscribeVehicleData.parameters = common.EMPTY_ARRAY
  pTbl.policy_table.vehicle_data = nil
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Unsubscribe from StabilityControlsStatus is not allowed by policies",
  common.processRPCSubscriptionDisallowed, { "UnsubscribeVehicleData", "stabilityControlsStatus" })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
