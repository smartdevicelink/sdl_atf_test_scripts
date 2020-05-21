---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL responds with resultCode "GENERIC_ERROR" to GetVehicleData request if HMI response is
-- invalid
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPC GetVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends GetVehicleData response with invalid type of handsOffSteering parameter
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = "GENERIC_ERROR") to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local rpc = "GetVehicleData"
local handsOffSteeringValue = 123

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("RPC GetVehicleData, HMI sends invalid response", common.processRPCgenericError,
  { rpc, handsOffSteeringValue })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
