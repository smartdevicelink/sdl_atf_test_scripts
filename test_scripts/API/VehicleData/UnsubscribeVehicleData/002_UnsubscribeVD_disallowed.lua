---------------------------------------------------------------------------------------------------
-- Description: Check that SDL rejects UnsubscribeVehicleData request with resultCode "DISALLOWED"
-- if <vd_param> parameter is not allowed by policy
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) <vd_param> parameter is not allowed by policies for UnsubscribeVehicleData RPC
-- 3) App is registered and subscribed to <vd_param> parameter
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local result = "DISALLOWED"

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
      [common.rpc.unsub] = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = params
      },
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
  common.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.sub, param })
  common.Step("RPC " .. common.rpc.unsub .. " DISALLOWED", common.processRPCFailure,
    { common.rpc.unsub, param, result })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
