---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL rejects the request with `DISALLOWED` resultCode if app tries to get `gearStatus` vehicle data
--  in case `gearStatus` parameter is not present in app assigned policies after PTU.
--
-- Preconditions:
-- 1) `gearStatus` parameter exists in app assigned policies.
-- 2) App sends valid GetVehicleData request with gearStatus=true to the SDL.
-- 3) and SDL processes this requests successfully.
-- In case:
-- 1) Policy Table Update is performed and `gearStatus` parameter is unassigned for the app.
-- 2) App sends GetVehicleData request with gearStatus=true to the SDL.
-- SDL does:
--  a) not transfer this request to HMI.
--  b) send response GetVehicleData(success:false, resultCode:"DISALLOWED") to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "GetVehicleData"
local result = "DISALLOWED"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App sends GetVehicleData for gearStatus data", common.getVehicleData, { common.getGearStatusParams() })

common.Title("Test")
common.Step("PTU is performed, gearStatus is unassigned for the app", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("GetVehicleData for gearStatus data DISALLOWED", common.processRPCFailure, { rpc, result })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
