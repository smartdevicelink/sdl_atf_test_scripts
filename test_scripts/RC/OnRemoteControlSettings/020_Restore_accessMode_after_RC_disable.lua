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

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }
local rcRpcs = { "SetInteriorVehicleData", "ButtonPress" }
local accessModes = { "AUTO_ALLOW", "AUTO_DENY", "ASK_DRIVER" }


--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

local function disableRcFromHmi(self)
  commonRC.defineRAMode(false, nil, self)
end

local function enableRcFromHmi(self)
  commonRC.defineRAMode(true, nil, self)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("RAI2", commonRC.rai_n, { 2 })

runner.Title("Test")

for _, accessMode in pairs(accessModes) do
  runner.Title(accessMode .. " -> Disable RC -> " .. accessMode)
  runner.Step("Enable RC from HMI with " .. accessMode .." access mode", commonRC.defineRAMode, { true, accessMode })
  runner.Step("Disable RC from HMI", disableRcFromHmi)
  runner.Step("Enable RC from HMI without access mode", enableRcFromHmi)
  runner.Step("Activate App1", commonRC.activate_app)
  runner.Step("Check module " .. modules[1] .." App1 " .. rcRpcs[2] .. " allowed", commonRC.rpcAllowed, { modules[1], 1, rcRpcs[2] })
  runner.Step("Check module " .. modules[2] .." App1 " .. rcRpcs[1] .. " allowed", commonRC.rpcAllowed, { modules[2], 1, rcRpcs[1] })
  runner.Step("Activate App2", commonRC.activate_app, { 2 })
  if accessMode == "AUTO_ALLOW" then
    runner.Step("Check module " .. modules[1] .." App2 " .. rcRpcs[2] .. " allowed", commonRC.rpcAllowed, { modules[1], 2, rcRpcs[2] })
    runner.Step("Check module " .. modules[2] .." App1 " .. rcRpcs[1] .. " allowed", commonRC.rpcAllowed, { modules[2], 2, rcRpcs[1] })
  elseif accessMode == "AUTO_DENY" then
    runner.Step("Check module " .. modules[1] .." App2 " .. rcRpcs[2] .. " denied", commonRC.rpcDenied, { modules[1], 2, rcRpcs[2], "IN_USE" })
    runner.Step("Check module " .. modules[2] .." App2 " .. rcRpcs[1] .. " denied", commonRC.rpcDenied, { modules[2], 2, rcRpcs[1], "IN_USE" })
  elseif accessMode == "ASK_DRIVER" then
    runner.Step("Check module " .. modules[1] .." App2 " .. rcRpcs[1] .. "  allowed with driver consent", commonRC.rpcAllowedWithConsent, { modules[1], 2, rcRpcs[1] })
    runner.Step("Check module " .. modules[2] .." App2 " .. rcRpcs[2] .. "  allowed with driver consent", commonRC.rpcAllowedWithConsent, { modules[2], 2, rcRpcs[2] })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
