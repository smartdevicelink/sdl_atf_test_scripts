---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0199-Adding-GPS-Shift-support.md
-- Description:
-- In case:
-- 1) App registered and subscribed on RADIO
-- 2) HMI does not send "shifted" item in "stationLocation" parameter of "moduleData" parameter of OnInteriorVehicleData
--    notification
-- SDL does:
-- 1) Send OnInteriorVehicleData notification to mobile without "shifted" item in "stationLocation" parameter
--    of "moduleData" parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GpsShiftSupport/commonGpsShift')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditionsRC)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe on InteriorVehicleData, RADIO module", common.getInteriorVehicleData, { nil, true })

runner.Title("Test")
runner.Step("OnInteriorVehicleData, RADIO module, without shifted ", common.onInteriorVehicleData, { nil })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditionsRC)
