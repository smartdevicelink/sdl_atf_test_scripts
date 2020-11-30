---------------------------------------------------------------------------------------------------
-- Description: Check that SDL rejects SubscribeVehicleData request with resultCode "DISALLOWED"
-- if <vd_param> parameter is not allowed by policy after PTU
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
-- 2) HMI sends SubscribeVehicleData response with <vd_param> data to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = SUCCESS",
--   <vd_param> = <data received from HMI>) to App
-- 3) PTU is performed with disabling permissions for <vd_param> parameter
-- 4) App sends valid SubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = "DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local result = "DISALLOWED"

--[[ Local Function ]]
local function getVDGroup(pDisallowedParam)
  local params = {}
  for param in pairs(common.getVDParams(true)) do
    if param ~= pDisallowedParam then table.insert(params, param) end
  end
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
  common.Title("VD parameter: " .. param)
  common.Title("Preconditions")
  common.Step("Clean environment and update preloaded_pt file", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerApp)
  common.Step("RPC " .. common.rpc.sub, common.processSubscriptionRPC, { common.rpc.sub, param })

  common.Title("Test")
  common.Step("PTU with disabling permissions for VD parameter", policyTableUpdate, { param })
  common.Step("RPC " .. common.rpc.sub .. " DISALLOWED after PTU", common.processRPCFailure, { common.rpc.sub, result })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
