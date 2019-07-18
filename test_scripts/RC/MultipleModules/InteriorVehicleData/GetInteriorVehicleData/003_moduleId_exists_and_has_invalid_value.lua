---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sent "GetInteriorVehicleData" request containing "moduleId" of incorrect data type to the SDL.
--  SDL should decline this request answering with (resultCode = "INVALID_DATA").
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all module capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "LIGHT", moduleId = invalid_value) request to the SDL
--   Check:
--    SDL does NOT resend "RC.GetInteriorVehicleData" request to the HMI
--    SDL responds with "GetInteriorVehicleData"(success = false, resultCode = "INVALID_DATA")
-- 2-4) Repeat step #1 using "moduleId" of different data types to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local invalid_values = {
  boolean = true,
  array   = {1, 2, 3},
  numeric = 1234,
  empty   = common.EMPTY_ARRAY
}
local subscribeValue = true
local rcCapabilities = { LIGHT = common.DEFAULT }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.customModulesPTU, { "LIGHT" })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for k, invValue in pairs(invalid_values) do
  runner.Step("Send GetInteriorVehicleData rpc for LIGHT module with invalid "..k.." moduleId",
    common.rpcReject, { "LIGHT", invValue, 1, "GetInteriorVehicleData", subscribeValue, "INVALID_DATA"})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
