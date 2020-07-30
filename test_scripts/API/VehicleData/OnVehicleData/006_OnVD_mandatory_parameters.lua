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

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)

common.Title("Test")
for param in pairs(common.mandatoryVD) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC, { common.rpc.sub, param })
  for caseName, value in pairs(common.getMandatoryOnlyCases(param)) do
    common.Step("RPC " .. common.rpc.on .. " with " .. caseName .. " Transfered", common.sendOnVehicleData,
      { param, common.isExpected, value })
  end
  for caseName, value in pairs(common.getMandatoryMissingCases(param)) do
    common.Step("RPC " .. common.rpc.on .. " with " .. caseName .. " Ignored", common.sendOnVehicleData,
      { param, common.isNotExpected, value })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
