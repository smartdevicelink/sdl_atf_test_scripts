----------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes OnVehicleData notification with <vd_param> parameter
-- Positive cases for all possible values for Enum and Boolean VD parameters and sub-parameters
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, OnVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to <vd_param> parameter data
--
-- In case:
-- 1) HMI sends valid OnVehicleData notification with <vd_param> parameter data to SDL
-- (iterate trough all possible enum and boolean values of applicable parameters)
-- SDL does:
-- - a) transfer this notification to App
-- Exception: Notification for unsubscribable VD parameter is not transfered
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Constants ]]
local testTypes = {
  common.testType.ENUM_ITEMS,
  common.testType.BOOL_ITEMS
}

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("Register App", common.registerApp)
common.runner.Step("Activate App", common.activateApp)

common.runner.Title("Test")
common.runner.getTestsForOnVD(testTypes)

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
