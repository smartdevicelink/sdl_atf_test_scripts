---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL responds with resultCode: INVALID_DATA
--  to GetVehicleData requests with invalid data type of `windowStatus` parameter
--
-- In case:
-- 1) App sends valid GetVehicleData request with invalid data type of `windowStatus` parameter
-- SDL does:
--  a) respond GetVehicleData(success:false, "INVALID_DATA") to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local rpc = "GetVehicleData"
local resultCode = "INVALID_DATA"
local requestInvalidValue = 123

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData INVALID_DATA", common.processRPCFailure, { rpc, resultCode, requestInvalidValue })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
