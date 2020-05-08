---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0199-Adding-GPS-Shift-support.md
-- Description:
-- In case:
-- 1) Mobile sends GetVehicleData (gps) request
-- 2) SDL transfers this request to HMI
-- 3) HMI sends VehicleData response with "shifted" item
-- SDL does:
-- 1) Send GetVehicleData response to mobile with "shifted" item in "gps" parameter
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

runner.Title("Test")
for _, v in pairs(common.shiftValue) do
  runner.Step("Get GPS VehicleData, gps-shifted " .. tostring(v), common.getVehicleData, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
