---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC with 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs SubscribeVehicleData, UnsubscribeVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to handsOffSteering parameter
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends VehicleInfo.UnsubscribeVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    handsOffSteering = <data received from HMI>) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering data", common.processSubscriptionRPC, { rpc_sub })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " with handsOffSteering parameter",
  common.processSubscriptionRPC, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
