---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes OnVehicleData notification with 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs SubscribeVehicleData, OnVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to handsOffSteering data
--
-- In case:
-- 1) HMI sends valid VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) transfer this notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local handsOffSteeringValues = { true, false }
local rpc = "SubscribeVehicleData"
local expected = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering parameter", common.processSubscriptionRPC, { rpc })

common.Title("Test")
for _, value in pairs(handsOffSteeringValues) do
  common.Step("HMI sends OnVehicleData notification with handsOffSteering " .. tostring(value),
    common.sendOnVehicleData, { expected, value })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
