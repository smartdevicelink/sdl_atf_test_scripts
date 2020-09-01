---------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "GENERIC_ERROR" to GetVehicleData request
-- if HMI response for <vd_param> parameter is invalid
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
-- 2) HMI sends GetVehicleData response with invalid type of <vd_param> parameter
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = "GENERIC_ERROR") to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for param, value in common.spairs(common.getVDParams()) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC " .. common.rpc.get .. " invalid HMI response", common.processRPCgenericError,
    { common.rpc.get, param, common.getInvalidData(value) })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
