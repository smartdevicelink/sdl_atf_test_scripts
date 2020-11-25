----------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes OnVehicleData notification with <vd_param> parameter
-- Positive/Negative cases for boundary values for all VD parameters and sub-parameters
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, OnVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to <vd_param> parameter data
--
-- In case:
-- 1) HMI sends OnVehicleData notification with valid data for <vd_param> parameter to SDL
-- (closest lower/upper values to the defined boundary)
-- SDL does:
-- - a) transfer this notification to App
-- Exception: Notification for unsubscribable VD parameter is not transfered
-- 2) HMI sends OnVehicleData notification with invalid data for <vd_param> parameter to SDL
-- (closest lower/upper values to the defined boundary)
-- SDL does:
-- - a) not transfer this notification to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Constants ]]
local testTypes = {
  common.testType.LOWER_IN_BOUND,
  common.testType.UPPER_IN_BOUND,
  common.testType.LOWER_OUT_OF_BOUND,
  common.testType.UPPER_OUT_OF_BOUND
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.getTestsForOnVD(testTypes)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
