---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: Check that SDL successfully processes VehicleData RPCs with `gearStatus` parameter
--  in case app version is equal to parameter version
--
-- Preconditions:
-- 1) App is registered with syncMsgVersion=6.0
-- 2) The parameter `gearStatus` has since=6.0 in DB and API.
-- In case:
-- 1) App requests Get/Sub/UnsubscribeVehicleData with gearStatus=true.
-- SDL does:
--  a) process the requests successful.
-- 2) HMI sends valid OnVehicleData notification with `gearStatus` data.
-- SDL does:
--  a) process the OnVehicleData notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

-- [[ Test Configuration ]]
common.getAppParams().syncMsgVersion.majorVersion = 6
common.getAppParams().syncMsgVersion.minorVersion = 0

-- [[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for gearStatus", common.getVehicleData)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc_sub })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData)
common.Step("App unsubscribes from gearStatus data", common.processSubscriptionRPC, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
