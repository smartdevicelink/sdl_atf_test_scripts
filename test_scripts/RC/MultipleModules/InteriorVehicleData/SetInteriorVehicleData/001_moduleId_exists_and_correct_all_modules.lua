---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  HMI sent all modules capabilities to the SDL. Mobile App consequently sends "SetInteriorVehicleData" requests
--  containing "moduleId" parameter to every available module.
--  SDL should use this parameters in its communication with HMI and App.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "SetInteriorVehicleData"(moduleType = "RADIO", moduleId = "00bd6d93", radioControlData) request
--     to the SDL
--   Check:
--    SDL resends "RC.SetInteriorVehicleData" (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData) request
--     to the HMI
--    HMI sends "RC.SetInteriorVehicleData"(moduleType = "RADIO", moduleId = "00bd6d93", radioControlData) response
--     to the SDL
--    SDL resends "SetInteriorVehicleData"
--     (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData, resultCode = "SUCCESS") response to the App
-- 2-6) Repeat step #1 but selecting another one from the remaining available modules
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = {}
for _, v in pairs(common.getRcModuleTypes()) do rcCapabilities[v] = common.DEFAULT end      -- enable all possible RC
                                                                                            -- capabilities in HMI
local subscribeData = {
  RADIO = common.getRcCapabilities().RADIO[1].moduleInfo.moduleId,
  CLIMATE = common.getRcCapabilities().CLIMATE[1].moduleInfo.moduleId,
  SEAT = common.getRcCapabilities().SEAT[1].moduleInfo.moduleId,
  AUDIO = common.getRcCapabilities().AUDIO[1].moduleInfo.moduleId,
  LIGHT = common.getRcCapabilities().LIGHT.moduleInfo.moduleId,
  HMI_SETTINGS = common.getRcCapabilities().HMI_SETTINGS.moduleInfo.moduleId
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for moduleType, moduleId in pairs(subscribeData) do
  runner.Step("Send request for ".. moduleType .." module", common.processRpc,
    { moduleType, moduleId, 1, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
