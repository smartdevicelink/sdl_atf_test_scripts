---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2448
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered
-- 3. App is in FULL HMI level
-- 4. PTU is performed successfully
-- 5. AddSubMenu is added
-- 6. HMI sends BC.OnExitAllApplications(reason = MASTER_RESET)
-- SDL does:
--  a. clear app's persist data
--  b. stop working
-- 7. HMI and SDL are started
-- 8. App registers with actual hashID
-- SDL does:
--  a. register app with resultCode RESUME_FAILED
--  b. not resume HMI level
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/5_0/2448_cleansing_app_info_after_MASTER_RESET_FACTORY_DEFAULTS/common")

--[[ Local Variables ]]
local shutDownReason = "MASTER_RESET"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile", common.start)
common.Step("Register app", common.registerApp)
common.Step("Activate app", common.activateApp)
common.Step("PTU", common.policyTableUpdate)
common.Step("AddSubMenu", common.AddSubMenu)

common.Title("Test")
common.Step("Waiting for SDL stores resumption data", common.waitUntilResumptionDataIsStored)
common.Step(shutDownReason, common.shutignDown, { shutDownReason })

common.Step("Start SDL, HMI, connect Mobile", common.start)
common.Step("App registration without resumption", common.appResumption, { true })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
