---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2439
---------------------------------------------------------------------------------------------------
-- Description: SDL responds with GetVehicleData(success = true, resultCode = "VEHICLE_DATA_NOT_AVAILABLE")
--  in case HMI responds with result struct
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
-- 3. PTU is performed with "Location-1" group
-- Steps:
-- 1. Mobile app requests GetVehicleData(speed = true, gps = true)
-- 2. HMI responds with `DATA_NOT_AVAILABLE` result code in result struct
-- SDL does:
--  - sends GetVehicleData(success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE") to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/5_0/2439_3014/common')

--[[ Local Variables ]]
local testData = {
  request = { speed = true, gps = true },
  respFunc = function(data)
    common.getHMIConnection():SendResponse(data.id, data.method, "DATA_NOT_AVAILABLE") end,
  respExp = { success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE" }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Update ptu", common.policyTableUpdate)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Sets GetVehicleData", common.getVehicleData, { testData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
