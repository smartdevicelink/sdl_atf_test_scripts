---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0199-Adding-GPS-Shift-support.md
-- Description:
-- In case:
-- 1) Mobile sends GetInteriorVehicleData request
-- 2) SDL transfers this request to HMI
-- 3) HMI sends "shifted" item in "stationLocation" parameter of "moduleData" parameter of GetInteriorVehicleData
--    response
-- SDL does:
-- 1) Send GetInteriorVehicleData response to mobile with "shifted" item in "stationLocation" parameter of
--    "moduleData" parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GpsShiftSupport/commonGpsShift')
local commonRC = require("test_scripts/RC/commonRC")

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, v in pairs(common.shiftValue) do
    runner.Step("GetInteriorVehicleData RADIO module, shifted " .. tostring(v), common.getInteriorVehicleData, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
