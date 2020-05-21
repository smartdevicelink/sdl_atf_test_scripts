---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App if 'handsOffSteering' parameter is not
-- allowed by policy
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) 'handsOffSteering' is Not allowed by policies for OnVehicleData RPC
-- 3) App is registered
-- 4) App is subscribed to handsOffSteering parameter
--
-- In case:
-- 1) HMI sends valid VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) ignored this notification and not transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local handsOffSteeringValues = { true, false }
local rpc = "SubscribeVehicleData"
local notExpected = 0
local VDGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = {"handsOffSteering"}
    },
    OnVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = { "gps" }
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering parameter", common.processSubscriptionRPC, { rpc })

common.Title("Test")
for _, value in pairs(handsOffSteeringValues) do
  common.Step("HMI sends OnVehicleData notification not allowed by policy, handsOffSteering-" .. tostring(value),
  common.sendOnVehicleData, { notExpected, value })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
