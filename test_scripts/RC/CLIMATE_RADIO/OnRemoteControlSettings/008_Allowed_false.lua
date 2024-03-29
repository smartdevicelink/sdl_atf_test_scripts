---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/11
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/RC/rc_enabling_disabling.md
-- Item: Use Case 1: Main Flow (updates https://github.com/smartdevicelink/sdl_core/issues/2173)
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- SDL received OnRemoteControlSettings (allowed:false) from HMI
--
-- SDL must:
-- 1) store RC state allowed:false internally
-- 2) keep all applications with appHMIType REMOTE_CONTROL registered and in current HMI levels
-- 3) unsubscribe all REMOTE_CONTROL applications from OnInteriorVehicleData notifications for all HMI modules internally
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcRpcs = {"GetInteriorVehicleData", "SetInteriorVehicleData", "ButtonPress"}

--[[ Local Functions ]]
local function PTUfunc(tbl)
  local notRcAppConfig = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" },
    groups_primaryRC = { "Base-4"},
    AppHMIType = { "NAVIGATION" }
  }
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID] = commonRC.getRCAppConfig()
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID] = commonRC.getRCAppConfig()
  tbl.policy_table.app_policies[config.application3.registerAppInterfaceParams.fullAppID] = notRcAppConfig
end

local function disableRcFromHmi()
  local mobileSession1 = commonRC.getMobileSession(1)
  local mobileSession2 = commonRC.getMobileSession(2)
  local mobileSession3 = commonRC.getMobileSession(3)

  commonRC.defineRAMode(false, nil)

  mobileSession1:ExpectNotification("OnHMIStatus"):Times(0)
  mobileSession2:ExpectNotification("OnHMIStatus"):Times(0)
  mobileSession3:ExpectNotification("OnHMIStatus"):Times(0) -- NAVIGATION app
  commonRC.wait(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions, { false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerApp)
runner.Step("PTU", commonRC.policyTableUpdate, { PTUfunc })
runner.Step("Activate App1", commonRC.activateApp)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })
runner.Step("Activate App2", commonRC.activateApp, { 2 })
runner.Step("Subscribe App2 on CLIMATE module", commonRC.subscribeToModule, { "CLIMATE", 2 })
runner.Step("Subscribe App1 on RADIO module", commonRC.subscribeToModule, { "RADIO", 1 })
runner.Step("RAI3", commonRC.registerAppWOPTU, { 3 })
runner.Step("Activate App3", commonRC.activateApp, { 3 })

runner.Title("Test")
runner.Step("Disable RC from HMI", disableRcFromHmi)

for _, mod in pairs(commonRC.modules)  do
  -- Apps are not subscribed from RC modules
  runner.Step("Check App1 is not subscribed on " .. mod, commonRC.isUnsubscribed, { mod, 1 })
  runner.Step("Check App2 is not subscribed on " .. mod, commonRC.isUnsubscribed, { mod, 2 })
  -- All RC RPCs rejected
  for _, rpc in pairs(rcRpcs) do
    runner.Step("Check module " .. mod .." App1 " .. rpc .. " rejected", commonRC.rpcDenied, { mod, 1, rpc, "USER_DISALLOWED" })
    runner.Step("Check module " .. mod .." App2 " .. rpc .. " rejected", commonRC.rpcDenied, { mod, 2, rpc, "USER_DISALLOWED" })
  end

end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
