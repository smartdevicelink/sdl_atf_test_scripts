---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received seat location capabilities containing all new parameters from the HMI.
--  SDL should transfer these capabilities in response to the "GetSystemCapability" request from a mobile App
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
--    SDL sent "GetSystemCapability" response
--     (systemCapabilityType = "SEAT_LOCATION", resultCode = "SUCCESS",seatLocationCapability = <custom_capabilities>)
--     to the mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customSeatLocation = {
  rows = 4,
  columns = 5,
  levels = 3,
  seats = {
    { grid = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
    { grid = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
    { grid = { col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
    { grid = { col = 1, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
    { grid = { col = 2, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
    { grid = { col = 0, row = 2, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
    { grid = { col = 2, row = 2, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
    { grid = { col = 0, row = 2, level = 1, colspan = 5, rowspan = 2, levelspan = 2 }}
  }
}

local responseParams = { seatLocationCapability = customSeatLocation }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.startSl, { customSeatLocation })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability for SEAT_LOCATION",
  common.sendGetSystemCapability, { 1, "SEAT_LOCATION", responseParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
