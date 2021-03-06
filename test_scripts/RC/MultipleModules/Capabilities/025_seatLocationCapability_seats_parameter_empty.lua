---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received seat location capabilities where "seats" array is empty.
--  In response to the "GetSystemCapability" request from mobile App SDL should substitute these capabilities
--  with the default ones.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent seatLocation capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetSystemCapability"(systemCapabilityType = "SEAT_LOCATION") request to the SDL
--   Check:
--    SDL sends "GetSystemCapability"
--     (systemCapabilityType = "SEAT_LOCATION", seatLocationCapability = <default_capabilities>, resultCode = "SUCCESS")
--     response to the mobile App
-----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customSeatLocation = {
  rows = 2,
  columns = 3,
  levels = 2,
  seats = common.json.EMPTY_ARRAY
}

local expectedParameters = common.getExpectedSLParameters()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set default RC capabilities", common.updateDefaultHmiSLCapabilities )
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startSl, { customSeatLocation })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability for SEAT_LOCATION",
  common.sendGetSystemCapability, { 1, "SEAT_LOCATION", expectedParameters })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
