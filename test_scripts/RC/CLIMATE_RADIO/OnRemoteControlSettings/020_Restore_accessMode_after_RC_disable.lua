---------------------------------------------------------------------------------------------------
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
-- - <AccessMode> -> Disable -> <AccessMode>
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcRpcs = { "SetInteriorVehicleData", "ButtonPress" }
local accessModes = { "AUTO_ALLOW", "AUTO_DENY", "ASK_DRIVER" }

--[[ Local Functions ]]
local function disableRcFromHmi()
  commonRC.defineRAMode(false, nil)
end

local function enableRcFromHmi()
  commonRC.defineRAMode(true, nil)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerAppWOPTU)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })

runner.Title("Test")

for _, accessMode in pairs(accessModes) do
  runner.Title(accessMode .. " -> Disable RC -> " .. accessMode)
  runner.Step("Enable RC from HMI with " .. accessMode .." access mode", commonRC.defineRAMode, { true, accessMode })
  runner.Step("Disable RC from HMI", disableRcFromHmi)
  runner.Step("Enable RC from HMI without access mode", enableRcFromHmi)
  runner.Step("Activate App1", commonRC.activateApp)
  runner.Step("Check module " .. commonRC.modules[1] .." App1 " .. rcRpcs[2] .. " allowed", commonRC.rpcAllowed, { commonRC.modules[1], 1, rcRpcs[2] })
  runner.Step("Check module " .. commonRC.modules[2] .." App1 " .. rcRpcs[1] .. " allowed", commonRC.rpcAllowed, { commonRC.modules[2], 1, rcRpcs[1] })
  runner.Step("Activate App2", commonRC.activateApp, { 2 })
  if accessMode == "AUTO_ALLOW" then
    runner.Step("Check module " .. commonRC.modules[1] .." App2 " .. rcRpcs[2] .. " allowed", commonRC.rpcAllowed, { commonRC.modules[1], 2, rcRpcs[2] })
    runner.Step("Check module " .. commonRC.modules[2] .." App1 " .. rcRpcs[1] .. " allowed", commonRC.rpcAllowed, { commonRC.modules[2], 2, rcRpcs[1] })
  elseif accessMode == "AUTO_DENY" then
    runner.Step("Check module " .. commonRC.modules[1] .." App2 " .. rcRpcs[2] .. " denied", commonRC.rpcDenied, { commonRC.modules[1], 2, rcRpcs[2], "IN_USE" })
    runner.Step("Check module " .. commonRC.modules[2] .." App2 " .. rcRpcs[1] .. " denied", commonRC.rpcDenied, { commonRC.modules[2], 2, rcRpcs[1], "IN_USE" })
  elseif accessMode == "ASK_DRIVER" then
    runner.Step("Check module " .. commonRC.modules[1] .." App2 " .. rcRpcs[1] .. "  allowed with driver consent", commonRC.rpcAllowedWithConsent, { commonRC.modules[1], 2, rcRpcs[1] })
    runner.Step("Check module " .. commonRC.modules[2] .." App2 " .. rcRpcs[2] .. "  allowed with driver consent", commonRC.rpcAllowedWithConsent, { commonRC.modules[2], 2, rcRpcs[2] })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
