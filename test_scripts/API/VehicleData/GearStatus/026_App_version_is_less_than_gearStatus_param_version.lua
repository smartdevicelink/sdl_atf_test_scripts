---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: Check that SDL processes VehicleData RPCs with `gearStatus` parameter as invalid
-- in case App is registered with syncMsVersion less than parameter version
--
-- Preconditions:
-- 1) App is registered with syncMsgVersion=5.0
-- 2) The parameter `gearStatus` has since=6.2 in DB and API.
-- In case:
-- 1) App requests Get/Sub/UnsubscribeVehicleData with gearStatus=true.
-- SDL does:
--  a) reject the request with INVALID_DATA resultCode as empty one.
-- 2) HMI sends OnVehicleData notification with `gearStatus` data
-- SDL does:
--  a) ignore this notification and not send it to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

-- [[ Test Configuration ]]
common.getAppParams().syncMsgVersion.majorVersion = 5
common.getAppParams().syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local result = "INVALID_DATA"
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData with gearStatus INVALID_DATA", common.processRPCFailure, { "GetVehicleData", result })
common.Step("SubscribeVehicleData with gearStatus INVALID_DATA", common.processRPCFailure,
  { "SubscribeVehicleData", result })
common.Step("Absence OnVehicleData with gearStatus",common.sendOnVehicleData,
  { common.getGearStatusParams(), notExpected })
common.Step("UnsubscribeVehicleData with gearStatus INVALID_DATA", common.processRPCFailure,
  { "UnsubscribeVehicleData", result })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
