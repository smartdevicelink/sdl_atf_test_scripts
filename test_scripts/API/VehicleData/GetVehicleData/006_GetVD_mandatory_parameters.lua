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

--[[ Local Functions ]]
local function processRPC(pRPC, pParam, pValue, pIsSuccess)
  local cid = common.getMobileSession():SendRPC(pRPC, { [pParam] = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { [pParam] = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = pValue })
    end)
  if pIsSuccess == true then
    local responseParams = {}
    responseParams[pParam] = pValue
    responseParams.success = true
    responseParams.resultCode = "SUCCESS"
    common.getMobileSession():ExpectResponse(cid, responseParams)
  else
    common.getMobileSession():ExpectResponse(cid,
      { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })
  end
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)

common.Title("Test")
for param in pairs(common.mandatoryVD) do
  common.Title("VD parameter: " .. param)
  for caseName, value in pairs(common.getMandatoryOnlyCases(param)) do
    common.Step("RPC " .. common.rpc.get .. " with " .. caseName .. " SUCCESS", processRPC,
      { common.rpc.get, param, value, true })
  end
  for caseName, value in pairs(common.getMandatoryMissingCases(param)) do
    common.Step("RPC " .. common.rpc.get .. " with " .. caseName .. " GENERIC_ERROR", processRPC,
      { common.rpc.get, param, value, false })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
