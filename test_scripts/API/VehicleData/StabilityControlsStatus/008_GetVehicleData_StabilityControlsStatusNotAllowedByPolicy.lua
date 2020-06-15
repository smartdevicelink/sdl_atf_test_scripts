---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description:
-- Check GetVehicleData RPC with `stabilityControlsStatus` parameter only
-- when GetVehicleData has not parameters which are allowed by Policies
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed, GetVehicleData has not parameters which are allowed by Policies,
--    including `stabilityControlsStatus` parameter
--
-- Steps:
-- 1) App sends GetVehicleData in (NONE, FULL, LIMITED, BACKGRAUND) level
-- (with stabilityControlsStatus = true) request to SDL
--    SDL does not send VehicleInfo.GetVehicleData (with stabilityControlsStatus = true) request to HMI
--    SDL sends VehicleInfo.GetVehicleData response ( resultCode = DISALLOWED, success = false )
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Local Variables ]]
local resultCode = "DISALLOWED"

--[[ Local Functions ]]
local function ptUpdateMin(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "Emergency-1" }
  local grp = pTbl.policy_table.functional_groupings["Emergency-1"]
  grp.rpcs.GetVehicleData.hmi_levels = {
    "FULL",
    "LIMITED",
    "BACKGROUND",
    "NONE"
  }
  grp.rpcs.GetVehicleData.parameters = common.EMPTY_ARRAY
  pTbl.policy_table.vehicle_data = nil
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptUpdateMin })

common.Title("Test")
common.Step("Send get vehicle data, NONE level", common.processGetVDunsuccess,
  { "stabilityControlsStatus", resultCode })
common.Step("App activate", common.activateApp)
common.Step("Send get vehicle data, FULL level", common.processGetVDunsuccess,
  { "stabilityControlsStatus", resultCode })
common.Step("Set HMI Level to Limited", common.hmiLeveltoLimited)
common.Step("Send get vehicle data, LIMITED level", common.processGetVDunsuccess,
  { "stabilityControlsStatus", resultCode })
  common.Step("Set HMI Level to BACKGROUND", common.hmiLeveltoBackground)
common.Step("Send get vehicle data, BACKGROUND level", common.processGetVDunsuccess,
  { "stabilityControlsStatus", resultCode })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
