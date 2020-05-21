---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL responds with resultCode "GENERIC_ERROR" to UnsubscribeVehicleData request if HMI response
-- is invalid
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs UnsubscribeVehicleData, SubscribeVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered and subscribed to handsOffSteering data
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI response is invalid
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "GENERIC_ERROR") to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local invalidData = {
  invalidType = 123,
  wrongDataType = "VEHICLEDATA_GPS",
  invalidDataType = 123
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering data", common.processSubscriptionRPC, { rpc_sub })

common.Title("Test")
for caseName, value in common.spairs(invalidData) do
  common.Step("RPC UnsubscribeVehicleData, invalid HMI response " .. caseName,
    common.processRPCgenericError, { rpc_unsub, value })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
