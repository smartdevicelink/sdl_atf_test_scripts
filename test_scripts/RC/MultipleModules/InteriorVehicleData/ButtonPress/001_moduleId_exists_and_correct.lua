---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  HMI sent all modules capabilities to the SDL.
--  Mobile App sends "ButtonPress" request with correct "moduleId" parameter.
--  SDL should correctly transfer this request with "moduleId" parameter, using it in further communication with
--  HMI and mobile App.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "ButtonPress"
--     (moduleType = "RADIO", moduleId = "00bd6d93", buttonName = "VOLUME_DOWN", buttonPressMode = "LONG")
--     request to the SDL
--   Check:
--    SDL resends "Buttons.ButtonPress"
--     (moduleType = "RADIO", moduleId = "00bd6d93", buttonName = "VOLUME_DOWN", buttonPressMode = "LONG")
--     request to the HMI
--    HMI sends "Buttons.ButtonPress"
--     (moduleType = "RADIO", moduleId = "00bd6d93", buttonName = "VOLUME_DOWN", buttonPressMode = "LONG")
--     response to the SDL
--    SDL sends "ButtonPress"(resultCode = SUCCESS", success = true) response to the App
-- 2) App sends "ButtonPress"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", buttonName = "FAN_DOWN", buttonPressMode = "LONG")
--     request to the SDL
--   Check:
--    SDL resends "Buttons.ButtonPress"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", buttonName = "FAN_DOWN", buttonPressMode = "LONG")
--     request to the HMI
--    HMI sends "Buttons.ButtonPress"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", buttonName = "FAN_DOWN", buttonPressMode = "LONG")
--     response to the SDL
--    SDL sends "ButtonPress"(resultCode = SUCCESS", success = true) response to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

local requestModuleData = {
  RADIO = {
    moduleType = "RADIO",
    moduleId = common.getRcCapabilities().RADIO[1].moduleInfo.moduleId,
    buttonName = "VOLUME_DOWN",
    buttonPressMode = "LONG"
  },
  CLIMATE = {
    moduleType = "CLIMATE",
    moduleId = common.getRcCapabilities().CLIMATE[1].moduleInfo.moduleId,
    buttonName = "FAN_DOWN",
    buttonPressMode = "LONG"
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for moduleType, moduleParams in pairs(requestModuleData) do
  runner.Step("Send ButtonPress request for "..moduleType.." module", common.rpcButtonPress, { moduleParams, 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
