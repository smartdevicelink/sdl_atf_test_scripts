---------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes SubscribeVehicleData RPC for two Apps with <vd_param> parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData RPC and <vd_param> parameter are allowed by policies
-- 3) App_1 and App_2 are registered
--
-- In case:
-- 1) App_1 sends valid SubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends successful SubscribeVehicleData response with <vd_param> data to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App_1
-- 3) App_2 sends valid SubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
-- <vd_param> = <data received from HMI>) to App_2
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local appId_1 = 1
local appId_2 = 2
local isExpectedSubscribeVDonHMI = true
local isNotExpectedSubscribeVDonHMI = false
local isExpected = 1
local isNotExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerApp, { appId_1 })
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })

common.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.Title("VD parameter: " .. param)
  common.Step("Absence of OnVehicleData for both apps",
    common.sendOnVehicleDataTwoApps, { param, isNotExpected, isNotExpected })
  common.Step("RPC " .. common.rpc.sub .. " for App_1",
    common.processSubscriptionRPC, { common.rpc.sub, param, appId_1, isExpectedSubscribeVDonHMI })
  common.Step("OnVehicleData for App_1",
    common.sendOnVehicleDataTwoApps, { param, isExpected, isNotExpected })
  common.Step("RPC " .. common.rpc.sub .. " for App_2",
    common.processSubscriptionRPC, { common.rpc.sub, param, appId_2, isNotExpectedSubscribeVDonHMI })
  common.Step("OnVehicleData for both apps",
    common.sendOnVehicleDataTwoApps, { param, isExpected, isExpected })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
