---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0199-Adding-GPS-Shift-support.md
-- Description:
-- In case:
-- 1) App registered and subscribed on vehicle data (gps)
-- 2) HMI sends "shifted" item in "gps" parameter of OnVehicleData notification
-- SDL does:
-- 1) Send OnVehicleData notification to mobile with "shifted" item in "gps" parameter
--  with the same value as those from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GpsShiftSupport/commonGpsShift')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe on GPS VehicleData", common.subscribeVehicleData)

runner.Title("Test")
for _, v in pairs(common.shiftValue) do
  runner.Step("Send On VehicleData with GpsShift " .. tostring(v), common.sendOnVehicleData, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
