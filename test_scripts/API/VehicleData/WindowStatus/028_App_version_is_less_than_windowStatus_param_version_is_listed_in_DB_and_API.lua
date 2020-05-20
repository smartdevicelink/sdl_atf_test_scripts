---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL processed VehicleData RPCs with 'windowStatus' parameter as invalid
-- in case App is registered with syncMsgVersion less than parameter version
--
-- Preconditions:
-- 1) App is registered with syncMsgVersion=5.0
-- 2) The parameter `windowStatus` has since=6.2 in DB and API
-- In case:
-- 1) App requests Get/Sub/UnsubVehicleData with windowStatus=true.
-- SDL does:
--  a) reject the request with resultCode INVALID_DATA as empty one
-- 2) HMI sends OnVehicleData notification with `windowStatus` data
-- SDL does:
--  a) ignore this notification and not send it to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

-- [[ Test Configuration ]]
common.getParams().syncMsgVersion.majorVersion = 5
common.getParams().syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local resultCode = "INVALID_DATA"
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for windowStatus " .. resultCode,
  common.processRPCFailure, { "GetVehicleData", resultCode })

common.Step("SubscribeVehicleData for windowStatus " .. resultCode,
  common.processRPCFailure, { "SubscribeVehicleData", resultCode })

common.Step("UnsubscribeVehicleData for windowStatus " .. resultCode,
  common.processRPCFailure, { "UnsubscribeVehicleData", resultCode})

common.Step("OnVehicleData for windowStatus data", common.sendOnVehicleData,
  { common.getWindowStatusParams(), notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
