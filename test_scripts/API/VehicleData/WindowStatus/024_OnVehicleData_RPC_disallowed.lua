---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL does not forward the OnVehicleData notification with 'windowStatus' parameter to App in
-- case `windowStatus` parameter does not exist in apps assigned policies.
--
-- In case:
-- 1) SubscribeVehicleData, OnVehicleData RPCs are allowed by policies
-- 2)`windowStatus` parameter does not exist in app's assigned policies for OnVehicleData RPC
-- 3) App is subscribed to windowStatus data.
-- 4) HMI sends OnVehicleData notification with windowStatus data
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local isPreloadedUpdate = true
local notExpected = 0
local VDGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = { "windowStatus" }
    },
    OnVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = { "gps" }
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions, { isPreloadedUpdate, VDGroup})
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("OnVehicleData with windowStatus data", common.sendOnVehicleData,
  { common.getWindowStatusParams(), notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
