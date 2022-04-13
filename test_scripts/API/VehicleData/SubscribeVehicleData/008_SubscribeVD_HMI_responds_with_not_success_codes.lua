---------------------------------------------------------------------------------------------------
-- Description: Check Processing of SubscribeVehicleData request
-- if HMI respond with unsuccessful resultCode for <vd_param> parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData RPC and <vd_param> parameter are allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid SubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI.
-- 2) HMI responds with "SUCCESS" result to SubscribeVehicleData request
--  and with not success result for <vd_param> vehicle data
-- SDL does:
-- - a) respond "SUCCESS", success:true and with unsuccessful resultCode for <vd_param> data to the mobile app
-- Note: expected behavior is under clarification in https://github.com/smartdevicelink/sdl_core/issues/3384
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local resultCodes = {
  "TRUNCATED_DATA",
  "DISALLOWED",
  "USER_DISALLOWED",
  "INVALID_ID",
  "VEHICLE_DATA_NOT_AVAILABLE",
  "DATA_NOT_SUBSCRIBED",
  "IGNORED",
  "DATA_ALREADY_SUBSCRIBED"
}

--[[ Local Variables ]]
local function subscribeToVDwithUnsuccessCodeForVD(pParam, pCode)
  local response = { dataType = common.vd[pParam], resultCode = pCode}
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", { [pParam] = true })
  local responseParam = pParam
  if pParam == "clusterModeStatus" then responseParam = "clusterModes" end
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { [pParam] = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [responseParam] = response })
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", [responseParam] = response })
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("Register App", common.registerApp)

common.runner.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Title("VD parameter: " .. param)
  for _, code in common.spairs(resultCodes) do
    common.runner.Step("RPC " .. common.rpc.sub .. " resultCode " .. code,
      subscribeToVDwithUnsuccessCodeForVD, { param, code })
  end
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
