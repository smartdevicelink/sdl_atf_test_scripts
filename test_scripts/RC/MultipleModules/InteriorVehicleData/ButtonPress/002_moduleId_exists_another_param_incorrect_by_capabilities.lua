---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sends to SDL "ButtonPress" request having correct value of "moduleId" and incorrect value of another
--  mandatory parameter. Check that in this case SDL declines the request, sending back a response with
--  ( resultCode = "INVALID_DATA" )
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "ButtonPress"
--     (moduleType = "RADIO", moduleId = "00bd6d93", buttonName = "INVALID_VALUE", buttonPressMode = "LONG")
--     request to the SDL
--   Check:
--    SDL does NOT resend "Buttons.ButtonPress" request to the HMI
--    SDL sends "ButtonPress"(resultCode = INVALID_DATA", success = false) response to the App
-- 2) Repeat step #1 for CLIMATE module sending "ButtonPress"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", buttonPressMode = "INVALID_VALUE") request to the SDL
--   Check:
--    SDL does NOT resend "Buttons.ButtonPress" request to the HMI
--    SDL sends "ButtonPress"(resultCode = INVALID_DATA", success = false) response to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = {RADIO = common.DEFAULT, CLIMATE = common.DEFAULT}
local requestModuleData = {
  RADIO = {
    moduleType = "RADIO",
    moduleId = common.getRcCapabilities().RADIO[1].moduleInfo.moduleId,
    buttonName = "INVALID_VALUE",                                             -- invalid value of "buttonName"
    buttonPressMode = "LONG"
  },
  CLIMATE = {
    moduleType = "CLIMATE",
    moduleId = common.getRcCapabilities().CLIMATE[1].moduleInfo.moduleId,
    buttonName = "FAN_DOWN",
    buttonPressMode = "INVALID_VALUE"                                         -- invalid value of "buttonPressMode"
  }
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
for moduleType, moduleParams in pairs(requestModuleData) do
  runner.Step("Send ButtonPress request with incorrect buttonName for "..moduleType.." module", common.rpcReject,
    { moduleType, moduleParams.moduleId, 1, "ButtonPress", moduleParams, "INVALID_DATA" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
