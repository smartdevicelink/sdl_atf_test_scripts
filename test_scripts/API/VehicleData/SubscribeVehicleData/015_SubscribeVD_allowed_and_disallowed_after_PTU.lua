---------------------------------------------------------------------------------------------------
-- Description: Check that SDL cuts off out param from SubscribeVehicleData request/response
-- in case <vd_param> parameter is not allowed by policy after PTU
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData RPC and <vd_param> parameter is disallowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid SubscribeVehicleData request to SDL (with all VD params incl. <vd_param>)
-- SDL does:
-- - a) cut off <vd_param>
-- - b) transfer this request to HMI
-- 2) HMI sends SubscribeVehicleData response to SDL (with all VD params incl. <vd_param>)
-- SDL does:
-- - a) cut off <vd_param>
-- - b) transfer SubscribeVehicleData response to App:
--  (success = true, resultCode = SUCCESS", <vd_param> = <data received from HMI>)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Conditions to skip test ]]
if #common.restrictedVDParams == 1 then
  common.runner.skipTest("Test is not applicable for one restricted VD parameter")
end

--[[ Local Variables ]]
local all_params = {}
for param in pairs(common.getVDParams(true)) do
  table.insert(all_params, param)
end
if #all_params == 0 then all_params = common.json.EMPTY_ARRAY end

--[[ Local Functions ]]
local function getVDGroup(pDisallowedParam)
  local params = {}
  for param in pairs(common.getVDParams(true)) do
    if param ~= pDisallowedParam then table.insert(params, param) end
  end
  if #params == 0 then params = common.json.EMPTY_ARRAY end
  return {
    rpcs = {
      [common.rpc.sub] = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = params
      }
    }
  }
end

local function policyTableUpdate(pDisallowedParam)
  local function ptUpdate(pt)
    pt.policy_table.functional_groupings["NewTestCaseGroup"] = getVDGroup(pDisallowedParam)
    pt.policy_table.app_policies[common.getAppParams().fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
  end
  common.policyTableUpdate(ptUpdate)
end

--[[ Scenario ]]
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Title("VD parameter: " .. param)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.runner.Step("Register App", common.registerApp)
  common.runner.Step("RPC " .. common.rpc.sub, common.processSubscriptionRPCMultipleParams,
    { common.rpc.sub, all_params })
  common.runner.Step("RPC " .. common.rpc.unsub, common.processSubscriptionRPCMultipleParams,
    { common.rpc.unsub, all_params })

  common.runner.Title("Test")
  common.runner.Step("PTU with disabling permissions for VD parameter", policyTableUpdate, { param })
  common.runner.Step("RPC " .. common.rpc.sub .. " filtered after PTU", common.processSubscriptionRPCMultipleParams,
    { common.rpc.sub, all_params, nil, nil, param })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
