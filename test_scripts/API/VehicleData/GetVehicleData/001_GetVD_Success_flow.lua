---------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes GetVehicleData RPC with <vd_param> parameter
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
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for param in common.spairs(common.getVDParams()) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC " .. common.rpc.get, common.getVehicleData, { param })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
