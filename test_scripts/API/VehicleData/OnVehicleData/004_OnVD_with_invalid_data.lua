---------------------------------------------------------------------------------------------------
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App
-- if HMI sends notification with invalid data for <vd_param> parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) OnVehicleData, SubscribeVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to <vd_param> parameter
--
-- In case:
-- 1) HMI sends OnVehicleData notification with invalid data for <vd_param> parameter to SDL
-- SDL does:
-- - a) ignore this notification and not transfer to App
-- Addition: Notification for unsubscribable VD parameter is not transfered as well
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Constants ]]
local testTypes = {
  common.testType.INVALID_TYPE
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
