---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) Mobile sends SubscribeOnVehicleData(gps(shifted=true/false)) request
-- 2) SDL transfers this request to HMI
-- 3) HMI sends "shifted" item (boolean) in "gps" parameter (Common.GPSData) of SubscribeOnVehicleData response
-- SDL does:
-- 1) Sends SubscribeOnVehicleData response to mobile with "shifted" item in "gps" parameter
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GpsShiftSupport/commonGpsShift')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function pTUpdateFunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "Location-1"}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Subscribe on GPS VehicleData", common.subscribeVehicleData)
for _, v in pairs(common.shiftValue) do
  runner.Step("Send On VehicleData with GpsShift " .. tostring(v), common.sendOnVehicleData, { v })
end


runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
