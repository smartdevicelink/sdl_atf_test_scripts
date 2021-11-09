---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2380
--
-- Description:
-- PoliciesManager must allow all requested <vd_param> parameters in case "parameters" field is omitted
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, UnsubscribeVehicleData, OnVehicleData RPCs are allowed by policies
-- 3) "parameters" field is omitted at PolicyTable for all RPCs
-- 4) App is registered
--
-- In case:
-- 1) App sends valid SubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends SubscribeVehicleData response with <vd_param> data to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--   <vd_param> = <data received from HMI>) to App
-- 3) HMI sends valid OnVehicleData notification with <vd_param> parameter data to SDL
-- SDL does:
-- - a) transfer this notification to App
-- Exception: Notification for unsubscribable VD parameter is not transfered
-- 4) App sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 5) HMI sends VI.UnsubscribeVehicleData response with <vd_param> parameter to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Function ]]
local function pTUpdateFunc(pt)
  local VDgroup = {
    rpcs = {
      [common.rpc.sub] = {
        parameters = nil,
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
      },
      [common.rpc.on] = {
        parameters = nil,
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
      },
      [common.rpc.unsub] = {
        parameters = nil,
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" },
      }
    }
  }
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
  pt.policy_table.app_policies[common.getAppParams().fullAppID].groups  = {"Base-4", "NewTestCaseGroup"}
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("Register App", common.registerApp)
common.runner.Step("PTU without 'parameters' field", common.policyTableUpdate, { pTUpdateFunc })

common.runner.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Title("VD parameter: " .. param)
  common.runner.Step("RPC " .. common.rpc.sub, common.processSubscriptionRPC, { common.rpc.sub, param })
  common.runner.Step("RPC " .. common.rpc.on, common.sendOnVehicleData, { param, common.isExpected })
  common.runner.Step("RPC " .. common.rpc.unsub, common.processSubscriptionRPC, { common.rpc.unsub, param })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
