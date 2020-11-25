---------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes OnVehicleData notification with <vd_param> parameter
-- with only mandatory sub-parameters
-- or with missing at least one mandatory sub-parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, OnVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to <vd_param> parameter data
--
-- In case:
-- 1) HMI sends valid OnVehicleData notification with <vd_param> parameter data to SDL
--   with only mandatory sub-parameters
-- SDL does:
-- - a) transfer this notification to App
-- 2) HMI sends OnVehicleData notification with <vd_param> parameter data to SDL
--   without at least one mandatory sub-parameter
-- SDL does:
-- - a) not transfer this notification to App
-- 4) HMI sends OnVehicleData notification with <vd_param> parameter data to SDL
--   with missing mandatory sub-parameter
-- SDL does:
-- - a) ignore this notification and not transfer to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Constants ]]
local testTypes = {
  common.testType.MANDATORY_ONLY,
  common.testType.MANDATORY_MISSING
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
