---------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "GENERIC_ERROR" to UnsubscribeVehicleData request
-- if HMI response for <vd_param> parameter is invalid
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, UnsubscribeVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered and subscribed to <vd_param> data
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends invalid response for <vd_param> parameter
-- SDL does:
-- - a) ignore this response
-- - b) send UnsubscribeVehicleData response with (success = false, resultCode = "GENERIC_ERROR") to App
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
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("Register App", common.registerApp)

common.runner.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Title("VD parameter: " .. param)
  common.runner.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.sub, param })
  for caseName, value in common.spairs(getInvalidData(param)) do
    common.runner.Step("RPC " .. common.rpc.unsub .. " invalid HMI response " .. caseName,
      common.processRPCgenericError, { common.rpc.unsub, param, value })
  end
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
