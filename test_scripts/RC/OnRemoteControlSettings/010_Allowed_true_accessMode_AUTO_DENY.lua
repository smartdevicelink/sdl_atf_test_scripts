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
-- 1) store RC state allowed:true and received from HMI internally
-- 2) allow RC functionality for applications with REMOTE_CONTROL appHMIType
--
-- Case: accessMode = "AUTO_DENY"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

local rcRpcs = {"SetInteriorVehicleData", "ButtonPress"}

--[[ Local Functions ]]

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

local function disableRcFromHmi(self)
  commonRC.defineRAMode(false, nil, self)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("RAI2", commonRC.rai_n, { 2 })
runner.Step("Disable RC from HMI", disableRcFromHmi)

runner.Title("Test")
runner.Step("Enable RC from HMI with AUTO_DENY access mode", commonRC.defineRAMode, { true, "AUTO_DENY"})
for _, mod in pairs(modules) do
  for _, rpc in pairs(rcRpcs) do
  	runner.Step("Activate App1", commonRC.activate_app)
    runner.Step("Check module " .. mod .." App1 " .. rpc .. " allowed", commonRC.rpcAllowed, { mod, 1, rpc })
    runner.Step("Activate App2", commonRC.activate_app, { 2 })
    runner.Step("Check module " .. mod .." App2 " .. rpc .. " denied", commonRC.rpcDenied, { mod, 2, rpc, "IN_USE" })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
