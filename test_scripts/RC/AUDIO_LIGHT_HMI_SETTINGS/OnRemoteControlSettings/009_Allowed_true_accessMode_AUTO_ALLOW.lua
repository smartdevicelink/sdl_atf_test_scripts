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
-- Case: accessMode = "AUTO_ALLOW"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--modules array does not contain "RADIO" because "RADIO" module has read only parameters
local modules = { "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = common.getRCAppConfig()
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = common.getRCAppConfig()
end

local function disableRcFromHmi()
  common.defineRAMode(false, nil)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI1, PTU", common.raiPTUn, { ptu_update_func })
runner.Step("RAI2", common.raiN, { 2 })
runner.Step("Disable RC from HMI", disableRcFromHmi)

runner.Title("Test")
runner.Step("Enable RC from HMI with AUTO_ALLOW access mode", common.defineRAMode, { true, "AUTO_ALLOW"})
for _, mod in pairs(modules) do
  runner.Step("Activate App1", common.activateApp)
  runner.Step("Check module " .. mod .." App1 SetInteriorVehicleData allowed", common.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  runner.Step("Activate App2", common.activateApp, { 2 })
  runner.Step("Check module " .. mod .." App2 SetInteriorVehicleData allowed", common.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
