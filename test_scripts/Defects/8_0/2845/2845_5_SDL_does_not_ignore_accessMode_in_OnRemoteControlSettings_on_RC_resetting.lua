---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2845
---------------------------------------------------------------------------------------------------
-- Description: Check SDL does not ignore "accessMode" parameter if "allowed" parameter does not exist
--  or "allowed" = false in the OnRemoteControlSettings notification
--  (checking of remaining of "accessMode" after resetting of RC)
--
-- In case:
-- 1. Two RC apps are registered
-- 2. RC functionality is allowed both apps by policy
-- 3. RC functionality is enabled from HMI via OnRemoteControlSettings without setting of access mode
--  OnRemoteControlSettings [allowed = true]
-- 4. Set <mode> access mode without allowed parameter via OnRemoteControlSettings
--  OnRemoteControlSettings [accessMode = <mode>] where <mode> is one of {"AUTO_DENY", "ASK_DRIVER", "AUTO_ALLOW"}
-- 5. RC functionality is reset from HMI via OnRemoteControlSettings without setting of access mode
-- OnRemoteControlSettings [allowed = false] and OnRemoteControlSettings [allowed = true]
--
-- SDL does:
--  - remain its behavior according <mode> accessMode applied before RC functionality reset
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_0/2845/common_2845')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local on = true
local off = false
local rcRpcs = { "SetInteriorVehicleData", "ButtonPress" }
local apps = { 1, 2 }
local accessModes = { "AUTO_DENY", "ASK_DRIVER", "AUTO_ALLOW" }

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
      runner.Title("Module: " .. mod .. "; RPC: " .. rpc)
      for _, mode in ipairs(accessModes) do
        runner.Title("Remaining of the access mode: " .. mode)
        runner.Step("Set " .. mode .. " access mode without allowed parameter", common.defineRAMode, { nil, mode })
        runner.Step("Activate App1", common.activateApp, { apps[1] })
        runner.Step("Check module " .. mod .." App1 " .. rpc .. " allowed", common.rpcAllowed, { mod, apps[1], rpc })
        runner.Step("Activate App2", common.activateApp, { apps[2] })
        runner.Step("Check module " .. mod .." App2 " .. rpc .. common.getResultDescription(mode),
          common.getFunctionWithParameters(mode, mod, rpc, apps[2]))
        runner.Step("Disable RC from HMI without setting of access mode", common.defineRAMode, { off, nil })
        runner.Step("Enable RC from HMI without setting of access mode", common.defineRAMode, { on, nil })
        runner.Step("Activate App1", common.activateApp, { apps[1] })
        runner.Step("Check module " .. mod .." App1 " .. rpc .. " allowed", common.rpcAllowed, { mod, apps[1], rpc })
        runner.Step("Activate App2", common.activateApp, { apps[2] })
        runner.Step("Check module " .. mod .." App2 " .. rpc .. common.getResultDescription(mode),
          common.getFunctionWithParameters(mode, mod, rpc, apps[2]))
        if mode == "AUTO_ALLOW" then
          runner.Step("Release module " .. mod, common.releaseModule, { mod, apps[2] })
        end
      end
    end
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
