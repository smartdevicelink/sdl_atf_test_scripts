---------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "GENERIC_ERROR" to SubscribeVehicleData request
-- if HMI response for <vd_param> parameter is invalid
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData RPC and <vd_param> parameter are allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid SubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends invalid response for <vd_param> parameter
-- SDL does:
-- - a) ignore this response
-- - b) send SubscribeVehicleData response with (success = false, resultCode = "GENERIC_ERROR") to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Functions ]]
local function getInvalidData(pParam)
  return {
    wrongDataType = { dataType = "UNKNOWN", resultCode = "SUCCESS" },
    wrongResultCode = { dataType = common.vd[pParam], resultCode = "UNKNOWN" }
  }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.Title("VD parameter: " .. param)
  for caseName, value in common.spairs(getInvalidData(param)) do
    common.Step("RPC " .. common.rpc.sub .. " invalid HMI response " .. caseName,
      common.processRPCgenericError, { common.rpc.sub, param, value })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
