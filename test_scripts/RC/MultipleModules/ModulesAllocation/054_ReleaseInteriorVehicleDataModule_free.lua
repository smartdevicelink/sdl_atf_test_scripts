---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check of releasing of free RC modules using ReleaseInteriorVehicleDataModule RPC
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules of each type to SDL
-- 3) Mobile is connected to SDL
-- 4) App1 (appHMIType: ["REMOTE_CONTROL"]) is registered from Mobile
-- 5) Multiple RC modules of different module types are free
-- 6) HMI level of App1 is FULL
--
-- Steps:
-- 1) Send ReleaseInteriorVehicleDataModule RPC for each of tested RC module from App1 to release RC modules
--     (moduleType: <moduleType>, moduleId: <moduleId>) from App1
--   Checks for each request:
--    SDL responds on ReleaseInteriorVehicleDataModule RPC with
--     resultCode:"IGNORED", info:"Module [<moduleType>:<moduleId>] is not allocated to this application.",
--     success:false
--    SDL does not release module and does not send OnRCStatus notifications to HMI and App
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appLocation = {
  [1] = common.grid.BACK_RIGHT_PASSENGER
}

local rcAppIds = { 1 }
local rcCapabilities = common.initHmiRcCapabilitiesForRelease(appLocation[1])
local testModulesArray = common.buildTestModulesArrayFirst(rcCapabilities)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: AUTO_ALLOW", common.defineRAMode, { true, "AUTO_ALLOW" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1 (Back seat)", common.setUserLocation, { 1, appLocation[1] })

runner.Title("Test")
for _, testModule in ipairs(testModulesArray) do
  runner.Step("Try to release free module [" .. testModule.moduleType .. ":" .. testModule.moduleId .. "]",
      common.releaseModuleWithInfoCheck,
      { 1, testModule.moduleType, testModule.moduleId, "IGNORED", "FREE_MODULE", rcAppIds })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
