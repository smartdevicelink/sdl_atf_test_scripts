---------------------------------------------------------------------------------------------------
-- Description: Check that SDL rejects UnsubscribeVehicleData request with resultCode "DISALLOWED"
-- if <vd_param> parameter is not allowed by policy after PTU
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
-- 2) HMI sends VI.UnsubscribeVehicleData response with <vd_param> data to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App
-- 3) App is subscribed to <vd_param> data again
-- 4) PTU is performed with disabling permissions for <vd_param> parameter
-- 5) App sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local result = "DISALLOWED"

--[[ Local Function ]]
local function getVDGroup(pDisallowedParam)
  local all_params = {}
  local params = {}
  for param in pairs(common.getVDParams(true)) do
    if param ~= pDisallowedParam then table.insert(params, param) end
    table.insert(all_params, param)
  end
  if #all_params == 0 then all_params = common.json.EMPTY_ARRAY end
  if #params == 0 then params = common.json.EMPTY_ARRAY end
  return {
    rpcs = {
      [common.rpc.sub] = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = all_params
      },
      [common.rpc.unsub] = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = params
      },
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
  common.runner.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.sub, param })
  common.runner.Step("RPC " .. common.rpc.unsub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.unsub, param })

  common.runner.Title("Test")
  common.runner.Step("PTU with disabling permissions for VD parameter", policyTableUpdate, { param })
  common.runner.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.sub, param })
  common.runner.Step("RPC " .. common.rpc.unsub .. " DISALLOWED after PTU", common.processRPCFailure,
    { common.rpc.unsub, param, result })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
