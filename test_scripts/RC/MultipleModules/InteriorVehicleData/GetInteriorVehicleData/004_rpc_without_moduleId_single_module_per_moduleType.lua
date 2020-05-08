---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sent "GetInteriorVehicleData" request with omitted "moduleId" parameter to every available
--  module when only one module is available per moduleType in capabilities.
--  SDL should transfer it to the HMI adding a default "moduleId" value to the request and use it in further
--  communications.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent capabilities where only one module per module type
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "RADIO", subscribe = true) request - "moduleId" is omitted
--   Check:
--    SDL resends "RC.GetInteriorVehicleData" (moduleType = "RADIO", moduleId = "00bd6d93", subscribe = true) request
--     to the HMI, adding the default "00bd6d93" value
--    HMI sends "RC.GetInteriorVehicleData"
--     (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData, isSubscribed = true) response to the SDL
--    SDL resends "GetInteriorVehicleData"
--     (moduleType = "RADIO", moduleId = "00bd6d93", radioControlData, resultCode = "SUCCESS") response to the App
-- 2-6) Repeat step #1 but selecting another one from the remaining available types of modules
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = {}
for _, v in pairs(common.getRcModuleTypes()) do rcCapabilities[v] = common.DEFAULT end

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
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for moduleType, moduleId in pairs(subscribeData) do
  runner.Step("Send GetInteriorVehicleData request with omitted moduleId for ".. moduleType .." module",
    common.subscribeToIVDataNoModuleId, { moduleType, moduleId, 1, true, "SUCCESS" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
