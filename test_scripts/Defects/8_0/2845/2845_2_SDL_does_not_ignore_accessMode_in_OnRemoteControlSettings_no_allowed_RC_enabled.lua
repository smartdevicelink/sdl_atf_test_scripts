---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2845
---------------------------------------------------------------------------------------------------
-- Description: Check SDL does not ignore "accessMode" parameter if "allowed" parameter does not exist
--  or "allowed" = false in the OnRemoteControlSettings notification
--  (checking of "accessMode" changes when RC is enabled)
--
-- In case:
-- 1. Two RC apps are registered
-- 2. RC functionality is allowed both apps by policy
-- 3. RC functionality is enabled from HMI via OnRemoteControlSettings without setting of access mode
--  OnRemoteControlSettings [allowed = true]
-- 4. Set <mode> access mode without allowed parameter via OnRemoteControlSettings
--  OnRemoteControlSettings [accessMode = <mode>] where <mode> is one of {"AUTO_DENY", "ASK_DRIVER", "AUTO_ALLOW"}
--
-- SDL does:
--  - apply received <mode> accessMode and does not enable/disable of RC functionality
--  - change its behavior according applied accessMode such as RC module allocation
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_0/2845/common_2845')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local on = true
local rcRpcs = { "SetInteriorVehicleData", "ButtonPress" }
local apps = { 1, 2 }
local checks = {
  { from = "AUTO_ALLOW", to = "ASK_DRIVER" },
  { from = "ASK_DRIVER", to = "AUTO_DENY" },
  { from = "AUTO_DENY", to = "AUTO_ALLOW" },
  { from = "AUTO_ALLOW", to = "AUTO_DENY" },
  { from = "AUTO_DENY", to = "ASK_DRIVER" },
  { from = "ASK_DRIVER", to = "AUTO_ALLOW" }
}

local isConsented = { }

--[[ Local Functions ]]
local function getFunctionWithParameters(pTo, pModuleType, pRpc, pAppId)
  if pTo == "AUTO_ALLOW" then return common.rpcAllowed, { pModuleType, pAppId, pRpc }
  elseif pTo == "AUTO_DENY" then return common.rpcDenied, { pModuleType, pAppId, pRpc, "IN_USE" }
  elseif pTo == "ASK_DRIVER" then
    if isConsented[pModuleType] == nil then
      isConsented[pModuleType] = true
      return common.rpcDeniedWithConsent, { pModuleType, pAppId, pRpc }
    end
    return common.rpcDeniedWithoutConsent, { pModuleType, pAppId, pRpc }
  end
  return nil, nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update preloaded PT with RC apps", common.preparePreloadedPT, { apps })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI1", common.registerAppWOPTU, { apps[1] })
runner.Step("RAI2", common.registerAppWOPTU, { apps[2] })
runner.Step("Enable RC from HMI without setting of access mode", common.defineRAMode, { on, nil })

runner.Title("Test")
for _, mod in pairs(common.modules)  do
  for _, rpc in pairs(rcRpcs) do
    if common.isRpcApplicable(mod, rpc) then
      runner.Title("RC is enabled; Module: " .. mod .. "; RPC: " .. rpc)
      for _, check in ipairs(checks) do
        runner.Title("Changing of access mode: " .. check.from .. " -> " .. check.to)
        runner.Step("Set " .. check.to .. " access mode without allowed parameter",
          common.defineRAMode, { nil, check.to })
        runner.Step("Activate App1", common.activateApp, { apps[1] })
        runner.Step("Check module " .. mod .." App1 " .. rpc .. " allowed", common.rpcAllowed, { mod, apps[1], rpc })
        runner.Step("Activate App2", common.activateApp, { apps[2] })
        runner.Step("Check module " .. mod .." App2 " .. rpc .. common.getResultDescription(check.to),
          getFunctionWithParameters(check.to, mod, rpc, apps[2]))
        if check.to == "AUTO_ALLOW" then
          runner.Step("Release module " .. mod, common.releaseModule, { mod, apps[2] })
        end
      end
    end
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
