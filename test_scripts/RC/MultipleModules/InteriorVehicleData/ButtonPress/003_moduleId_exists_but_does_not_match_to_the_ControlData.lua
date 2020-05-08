---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sends to the SDL "ButtonPress" request where "moduleId" has incorrect value.
--  Check that in this case SDL declines "ButtonPress" request and responds back to the mobile App with
--  ( resultCode = "UNSUPPORTED_RESOURCE" )
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "ButtonPress"
--     (moduleType = "RADIO", moduleId = "INCORRECT_ID", buttonName = "SOURCE", buttonPressMode = "LONG") request
--     to the SDL
--   Check:
--    SDL does NOT resend "Buttons.ButtonPress" request to the HMI
--    SDL responds with "ButtonPress"(success = false, resultCode = "UNSUPPORTED_RESOURCE") to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = {RADIO = common.DEFAULT}
local requestModuleData = {
  moduleType = "RADIO",
  moduleId = "INCORRECT_ID",
  buttonName = "SOURCE",
  buttonPressMode = "LONG"
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send ButtonPress with incorrect moduleId value", common.rpcReject,
  { "RADIO", "INCORRECT_ID", 1, "ButtonPress", requestModuleData, "UNSUPPORTED_RESOURCE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
