---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: Check that SDL processes SubscribeVehicleData RPC for two Apps with 'gearStatus' parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPC SubscribeVehicleData and gearStatus parameter are allowed by policies
-- 3) App_1 and App_2 are registered
-- In case:
-- 1) App_1 sends valid SubscribeVehicleData(gearStatus=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends successful VehicleInfo.SubscribeVehicleData response with gearStatus data to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    gearStatus = <data received from HMI>) to App_1
-- 3) App_2 sends valid SubscribeVehicleData(gearStatus=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
-- gearStatus = <data received from HMI>) to App_2
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variable ]]
local rpc = "SubscribeVehicleData"
local appId1 = 1
local appId2 = 2
local isExpectedSubscribeVDonHMI = true
local isNotExpectedSubscribeVDonHMI = false
local notExpected = 0
local expected = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerApp, { appId1 })
common.Step("Register App_2", common.registerAppWOPTU, { appId2 })
common.Step("Absence of OnVehicleData notification for both apps",
  common.onVehicleDataTwoApps, { notExpected })

common.Title("Test")
common.Step("App_1 subscribes to gearStatus data", common.processSubscriptionRPC,
  { rpc, appId1, isExpectedSubscribeVDonHMI })
common.Step("OnVehicleData with gearStatus data to App_1", common.sendOnVehicleData)
common.Step("App_2 subscribes to gearStatus data",
  common.processSubscriptionRPC, { rpc, appId2, isNotExpectedSubscribeVDonHMI })
common.Step("OnVehicleData notification for both apps",
  common.onVehicleDataTwoApps, { expected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
