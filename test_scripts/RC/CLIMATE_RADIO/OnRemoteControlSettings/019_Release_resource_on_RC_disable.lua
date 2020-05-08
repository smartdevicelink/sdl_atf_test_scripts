---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/11
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/rc_enabling_disabling.md
-- Item: Use Case 2: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- RC_functionality is disabled on HMI and HMI sends notification OnRemoteControlSettings (allowed:true, <any_accessMode>)
--
-- SDL must:
-- 1) store RC state allowed:true received from HMI internally
-- 2) allow RC functionality for applications with REMOTE_CONTROL appHMIType
--
-- Additional checks:
-- - Release resource on RC functionality disable
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcRpcs = { "SetInteriorVehicleData", "ButtonPress" }
local accessModes = { "AUTO_ALLOW", "AUTO_DENY", "ASK_DRIVER" }
local HMILevels = { "FULL", "NOT_FULL" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerAppWOPTU)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })

runner.Title("Test")

for _, initialAccessMode in pairs(accessModes) do
  for _, targetAccessMode in pairs(accessModes) do
    for _, appLevel in pairs(HMILevels) do
      runner.Title(initialAccessMode .. " -> Disable RC -> " .. targetAccessMode .. " (" .. appLevel .. ")")
      for _, mod in pairs(commonRC.modules)  do
        runner.Title("Module: " .. mod)
        runner.Step("Enable RC from HMI with " .. initialAccessMode .." access mode", commonRC.defineRAMode, { true, initialAccessMode })
        runner.Step("Activate App1", commonRC.activateApp)
        runner.Step("Check App1 " .. rcRpcs[1] .. " allowed", commonRC.rpcAllowed, { mod, 1, rcRpcs[1] })
        runner.Step("Disable RC from HMI", commonRC.defineRAMode, { false, initialAccessMode })
        runner.Step("Enable RC from HMI with " .. targetAccessMode .. " access mode", commonRC.defineRAMode, { true, targetAccessMode })
        if appLevel == "FULL" then
          runner.Step("Activate App2", commonRC.activateApp, { 2 })
          runner.Step("Check App2 " .. rcRpcs[2] .. " allowed", commonRC.rpcAllowed, { mod, 2, rcRpcs[2] })
        else
          runner.Step("Activate App2", commonRC.activateApp, { 2 })
          runner.Step("Activate App1", commonRC.activateApp, { 1 })
          runner.Step("Check App2 " .. rcRpcs[2] .. " allowed", commonRC.rpcAllowed, { mod, 2, rcRpcs[2] })
          runner.Step("Activate App2", commonRC.activateApp, { 2 })
        end
      end
    end
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
