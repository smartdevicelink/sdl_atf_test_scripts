---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL rejects the GetVehicleData request with resultCode: DISALLOWED
-- if app tries to get `windowStatus` vehicle data in case `windowStatus` parameter does not exist in assigned policies.
--
-- In case:
-- 1) GetVehicleData RPC is allowed by policies
-- 2)`windowStatus` parameter does not exist in app's assigned policies.
-- 3) App sends valid GetVehicleData requests with windowStatus=true to the SDL.
-- SDL does:
--  a) send GetVehicleData(success:false, "DISALLOWED") response to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local isPreloadedUpdate = true
local resultCode = "DISALLOWED"
local rpc = "GetVehicleData"
local VDGroup = {
  rpcs = {
    GetVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = { "gps" }
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions, { isPreloadedUpdate, VDGroup})
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData with windowStatus " .. resultCode, common.processRPCFailure, { rpc, resultCode })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
