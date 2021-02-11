----------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes GetVehicleData RPC with <vd_param> parameter
-- Positive/Negative cases for boundary values for all VD parameters and sub-parameters
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) GetVehicleData RPC and <vd_param> parameter are allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid GetVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends VI.GetVehicleData response with valid data for <vd_param> to SDL
-- (closest lower/upper values to the defined boundary)
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App
-- 3) App sends valid GetVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 4) HMI sends VI.GetVehicleData response with invalid data for <vd_param> to SDL
-- (closest lower/upper values to the defined boundary)
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = "GENERIC_ERROR")
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
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("Register App", common.registerApp)
common.runner.Step("Activate App", common.activateApp)

common.runner.Title("Test")
common.runner.getTestsForGetVD(testTypes)

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
