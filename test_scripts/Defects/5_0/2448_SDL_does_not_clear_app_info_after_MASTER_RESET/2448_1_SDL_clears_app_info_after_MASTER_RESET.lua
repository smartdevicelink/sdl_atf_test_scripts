---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2448
--
-- Reproduction Steps:
-- HMI and SDL are started.
-- Register and activate Application1.
-- HMI sends notification OnExitAllApplication{reason = MASTER_RESET}.
--
-- Expected Behavior:
-- All SDL data are cleaned and reset.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("test_scripts/Defects/5_0/2448_SDL_does_not_clear_app_info_after_MASTER_RESET/common")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App1", common.registerApp, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("PTU", common.policyTableUpdate)

runner.Title("Test")
runner.Step("Waiting for SDL stores resumption data", common.waitUntilResumptionDataIsStored)
runner.Step("Sending MASTER_RESET by HMI", common.HMISendToSDL_MASTER_RESET)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
