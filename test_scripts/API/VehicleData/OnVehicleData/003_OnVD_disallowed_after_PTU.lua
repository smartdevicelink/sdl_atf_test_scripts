---------------------------------------------------------------------------------------------------
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App
-- if <vd_param> parameter is not allowed by policy after PTU
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, OnVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered and subscribed to <vd_param> parameter
--
-- In case:
-- 1) HMI sends OnVehicleData notification with <vd_param> parameter data to SDL
-- SDL does:
-- - a) transfer this notification to App
-- 2) PTU is performed with disabling permissions for <vd_param> parameter
-- 3) HMI sends OnVehicleData notification with <vd_param> parameter data to SDL
-- SDL does:
-- - a) ignore this notification and not transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Functions ]]
local function getVDGroup(pDisallowedParam)
  local all_params = {}
  local params = {}
  for param in pairs(common.getVDParams(true)) do
    if param ~= pDisallowedParam then table.insert(params, param) end
    table.insert(all_params, param)
  end
  return {
    rpcs = {
      [common.rpc.sub] = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = all_params
      },
      [common.rpc.on] = {
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
  common.Step("Clean environment and update preloaded_pt file", common.preconditions, { getVDGroup(param) })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerApp)
  common.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC, { common.rpc.sub, param })
  common.Step("RPC " .. common.rpc.on .. " transferred", common.sendOnVehicleData, { param, common.isExpected })

  common.Title("Test")
  common.Step("PTU with disabling permissions for VD parameter", policyTableUpdate, { param })
  common.Step("RPC " .. common.rpc.on .. " ignored", common.sendOnVehicleData, { param, common.isNotExpected })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
