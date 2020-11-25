---------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes GetVehicleData RPC with <vd_param> parameter
-- with only mandatory sub-parameters in HMI response
-- or with missing at least one mandatory sub-parameter
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
-- 2) HMI sends VI.GetVehicleData response with <vd_param> data to SDL
--   with only mandatory sub-parameters
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App
-- 3) App sends valid GetVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 4) HMI sends VI.GetVehicleData response with <vd_param> data to SDL
--  with missing mandatory sub-parameter
-- SDL does:
-- - a) ignore HMI response
-- - b) send GetVehicleData response with (success = false, resultCode = "GENERIC_ERROR") to App
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
common.getTestsForGetVD(testTypes)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
