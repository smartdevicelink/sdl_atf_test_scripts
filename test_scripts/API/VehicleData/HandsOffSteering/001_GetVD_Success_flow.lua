---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes GetVehicleData RPC with 'handsOffSteering' parameter
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
-- 2) HMI sends VehicleInfo.GetVehicleData response with handsOffSteering data to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = "SUCCESS",
--    handsOffSteering = <data received from HMI>) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local handsOffSteeringValues = { true, false }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for _, value in pairs(handsOffSteeringValues) do
  common.Step("RPC GetVehicleData with handsOffSteering " .. tostring(value), common.getVehicleData, { value })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
