---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App if HMI sends notification with
-- invalid data
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs OnVehicleData, SubscribeVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to handsOffSteering parameter
--
-- In case:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with invalid data to SDL
-- SDL does:
-- - a) ignored this notification and not transfer to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local rpc_sub = "SubscribeVehicleData"
local invalidData = 123
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering data", common.processSubscriptionRPC, { rpc_sub })

common.Title("Test")
common.Step("HMI sends OnVD notification with invalid data", common.sendOnVehicleData, { notExpected, invalidData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
