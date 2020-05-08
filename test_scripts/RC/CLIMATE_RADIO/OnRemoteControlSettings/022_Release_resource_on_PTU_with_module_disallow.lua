---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 3: Alternative Flow 2
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- Any trigger of Policy Table Update happened and in received PTU module_1 is not in the list of assigned moduleTypes for RC_app_1
--
-- SDL must:
-- 1) SDL disallows all RPC for module_1 from RC_app_1 and releases module_1 from RC_app_1 control
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function PTUfunc1(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].moduleType = { "RADIO" }
end

local function PTUfunc2(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    moduleType = { "CLIMATE" },
    groups = { "Base-4", "RemoteControl" },
    AppHMIType = { "REMOTE_CONTROL" }
  }
  table.insert(tbl.policy_table.functional_groupings.RemoteControl.rpcs.OnInteriorVehicleData.hmi_levels, "NONE")
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID] = commonRC.getRCAppConfig()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions, { false })
runner.Step("Update SDL config", commonRC.setSDLIniParameter, { "ApplicationListUpdateTimeout", 5000 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerApp)
runner.Step("PTU with RADIO for App1", commonRC.policyTableUpdate, { PTUfunc1 })

runner.Title("Test")
runner.Step("Enable RC from HMI with AUTO_DENY access mode", commonRC.defineRAMode, { true, "AUTO_DENY"})
runner.Step("Activate App1", commonRC.activateApp)
-- App1: FULL
runner.Step("Module RADIO App1 ButtonPress allowed", commonRC.rpcAllowed, { "RADIO", 1, "ButtonPress" })
runner.Step("Subscribe App1 to RADIO", commonRC.subscribeToModule, { "RADIO", 1 })
runner.Step("Send notification OnInteriorVehicleData RADIO. App1 is subscribed", commonRC.isSubscribed, { "RADIO", 1 })
runner.Step("RAI2", commonRC.registerApp, { 2 })
runner.Step("PTU with CLIMATE for App1", commonRC.policyTableUpdate, { PTUfunc2 })
runner.Step("Module RADIO App1 SetInteriorVehicleData disallowed", commonRC.rpcDenied, { "RADIO", 1, "SetInteriorVehicleData", "DISALLOWED"})
runner.Step("Module CLIMATE App1 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData"})
runner.Step("Activate App2", commonRC.activateApp, { 2 })
-- App1: BACKGROUND, App2: FULL
runner.Step("Send notification OnInteriorVehicleData RADIO. App1 is unsubscribed", commonRC.isUnsubscribed, { "RADIO", 1 })
runner.Step("Module RADIO App2 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "RADIO", 2, "SetInteriorVehicleData"})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
