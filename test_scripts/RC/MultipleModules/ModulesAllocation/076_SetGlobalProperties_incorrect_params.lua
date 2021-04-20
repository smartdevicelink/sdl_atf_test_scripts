---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check unsuccessfull cases of using SetGlobalProperties RPC to set user location for RC modules allocation purposes
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) Mobile is connected to SDL
-- 3) App1 registered from Mobile
--    HMI level of App1 is FULL
--
-- Steps:
-- 1) Send SetGlobalProperties RPC with userLocation: <over bound values in grid with App1 location> from App1
--   Check:
--    SDL does not send RC.SetGlobalProperties request to HMI
--    SDL responds on SetGlobalProperties RPC with resultCode: INVALID_DATA
-- 2) Send SetGlobalProperties RPC with userLocation: <under bound values in grid with App1 location> from App1
--   Check:
--    SDL does not send RC.SetGlobalProperties request to HMI
--    SDL responds on SetGlobalProperties RPC with resultCode: INVALID_DATA
-- 3) Send SetGlobalProperties RPC with userLocation: <missed mandatory params in grid with App1 location> from App1
--   Check:
--    SDL does not send RC.SetGlobalProperties request to HMI
--    SDL responds on SetGlobalProperties RPC with resultCode: INVALID_DATA
-- 4) Send SetGlobalProperties RPC with userLocation: <absent grid with App1 location> from App1
--   Check:
--    SDL does not send RC.SetGlobalProperties request to HMI
--    SDL responds on SetGlobalProperties RPC with resultCode: INVALID_DATA
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local grids = {
  over_bound = { col = 101, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 },
  under_bound = { col = 0, row = -2 },
  missed_mandatory = { colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("Send SetGlobalProperties with userLocation with value which over bound in grid",
    common.setUserLocation, { 1, grids.over_bound, "INVALID_DATA" })
runner.Step("Send SetGlobalProperties with userLocation with value which under bound in grid",
    common.setUserLocation, { 1, grids.under_bound, "INVALID_DATA" })
runner.Step("Send SetGlobalProperties with userLocation with absent mandatory parameter in grid",
    common.setUserLocation, { 1, grids.missed_mandatory, "INVALID_DATA" })
runner.Step("Send SetGlobalProperties with userLocation with absent grid",
    common.setUserLocation, { 1, nil, "INVALID_DATA" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
