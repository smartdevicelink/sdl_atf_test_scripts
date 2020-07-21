---------------------------------------------------------------------------------------------------
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App
-- if <vd_param> parameter is not allowed by policy
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) <vd_param> is not allowed by policies for OnVehicleData RPC
-- 3) App is registered
-- 4) App is subscribed to <vd_param> parameter
--
-- In case:
-- 1) HMI sends valid OnVehicleData notification with <vd_param> parameter data to SDL
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

--[[ Scenario ]]
for param in common.spairs(common.getVDParams(true)) do
  common.Title("VD parameter: " .. param)
  common.Title("Preconditions")
  common.Step("Clean environment and update preloaded_pt file", common.preconditions, { getVDGroup(param) })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerApp)

  common.Title("Test")
  common.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC, { common.rpc.sub, param })
  common.Step("RPC " .. common.rpc.on .. " ignored", common.sendOnVehicleData, { param, common.isNotExpected })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
