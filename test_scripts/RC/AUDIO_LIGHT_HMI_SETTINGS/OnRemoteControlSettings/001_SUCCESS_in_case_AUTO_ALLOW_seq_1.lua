---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #1
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with allowed:true
-- 2) and "accessMode" = "AUTO_ALLOW" or without "accessMode" parameter at all
-- 3) and RC_module on HMI is alreay in control by RC-application
-- SDL must:
-- 1) provide access to RC_module for the second RC_application in HMILevel FULL after it sends control RPC
-- (either SetInteriorVehicleData or ButtonPress) for the same RC_module without asking a driver
-- 2) process the request from the second RC_application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
--modules array does not contain "RADIO" because "RADIO" module has read only parameters
local modules = { "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS" }
local access_modes = { nil, "AUTO_ALLOW" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  common.AddOnRCStatusToPT(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = common.getRCAppConfig()
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = common.getRCAppConfig()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI1, PTU", common.raiPTUn, { ptu_update_func })
runner.Step("RAI2", common.raiN, { 2 })

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  for i = 1, #access_modes do
    runner.Title("Access mode: " .. tostring(access_modes[i]))
    -- set control for App1
    runner.Step("Activate App1", common.activateApp)
    runner.Step("App1 SetInteriorVehicleData", common.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
    -- set RA mode
    runner.Step("Set RA mode", common.defineRAMode, { true, access_modes[i] })
    -- set control for App2 --> Allowed
    runner.Step("Activate App2", common.activateApp, { 2 })
    runner.Step("App2 SetInteriorVehicleData", common.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
