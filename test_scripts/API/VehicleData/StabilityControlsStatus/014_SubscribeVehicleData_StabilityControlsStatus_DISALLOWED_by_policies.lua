---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check subscription on StabilityControlsStatus data which is disallowed by Policies
--   via SubscribeVehicleData RPC
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed and StabilityControlsStatus is not allowed
-- 4) App is activated

-- Steps:
-- 1) App sends SubscribeVehicleData request with (stabilityControlsStatus = true) to SDL
-- SDL does not send VehicleInfo.SubscribeVehicleData request to HMI
-- SDL sends SubscribeVehicleData response with (success: false, resultCode: "DISALLOWED",
--   stabilityControlsStatus = { resultCode = "DISALLOWED", dataType = "VEHICLEDATA_STABILITYCONTROLSSTATUS"})
-- 2) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus data
-- SDL does not send OnVehicleData notification with received from HMI data to App
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
  grp.rpcs.SubscribeVehicleData.parameters = common.EMPTY_ARRAY
  pTbl.policy_table.vehicle_data = nil
end

--[[ Local variables ]]
local vdNameDisallowed = "stabilityControlsStatus"
local mobileRequest = {
  [vdNameDisallowed] = true
}
local hmiRequest = {}
local mobileResponse = {
  success = false,
  resultCode = "DISALLOWED",
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Subscribe on " .. vdNameDisallowed .. " VehicleData, " ..
  vdNameDisallowed .. " is not allowed by policies",
  common.processSubscribeVD, { mobileRequest, hmiRequest, nil, mobileResponse })
common.Step("Ignore OnVehicleData with " .. vdNameDisallowed .. " data",
  common.checkNotificationIgnored, {{ vdNameDisallowed }})

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
