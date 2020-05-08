---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/7
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/Policy_Support_of_basic_RC_functionality.md
-- Item: Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [SDL_RC] Button press event emulation
--
-- Description:
-- In case:
-- 1) Non remote-control application is registered on SDL
-- 2) and SDL received ButtonPress request from this App
-- SDL must:
-- 1) Disallow remote-control RPCs for this app (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function PTUfunc(tbl)
  local appId = config.application1.registerAppInterfaceParams.fullAppID
  tbl.policy_table.app_policies[appId].AppHMIType = { "DEFAULT" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions, { false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerApp)
runner.Step("PTU", commonRC.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("ButtonPress_CLIMATE", commonRC.rpcDenied, {"CLIMATE", 1, "ButtonPress", "DISALLOWED"})
runner.Step("ButtonPress_RADIO", commonRC.rpcDenied, {"RADIO", 1, "ButtonPress", "DISALLOWED"})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
