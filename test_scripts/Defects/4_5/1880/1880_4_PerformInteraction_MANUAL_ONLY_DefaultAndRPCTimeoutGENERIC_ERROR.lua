---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartDeviceLink/sdl_core/issues/1880
---------------------------------------------------------------------------------------------------
-- Description: In case SDL transfers PerformInteraction(MANUAL_ONLY) with own timeout from mobile app to HMI
--  and HMI does NOT respond during <DefaultTimeout> + <*RPCs_own_timeout>
--  SDL must respond 'GENERIC_ERROR, success:false' to mobile app
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
-- 3. CreateInteractionChoiceSet is added
-- 4. Mobile app requests PerformInteraction(MANUAL_ONLY)
-- SDL does:
-- - request VR.PerformInteraction and UI.PerformInteraction to HMI
-- - start timeout <DefaultTimeout> + <*RPCs_own_timeout> for expecting UI response
-- 5. HMI does not respond to UI and VR requests during <DefaultTimeout> + <*RPCs_own_timeout>
-- SDL does:
-- - respond 'GENERIC_ERROR, success:false' to mobile app after <DefaultTimeout> + <*RPCs_own_timeout> is expired
-- 6. Mobile app requests PerformInteraction(MANUAL_ONLY)
-- SDL does:
-- - request VR.PerformInteraction and UI.PerformInteraction to HMI
-- - start timeout <DefaultTimeout> + <*RPCs_own_timeout> for expecting UI response
-- 7. HMI responds to VR request in 2 seconds
-- 8. HMI does not respond to UI request during <DefaultTimeout> + <*RPCs_own_timeout>
-- SDL does:
-- - respond 'GENERIC_ERROR, success:false' to mobile app after <DefaultTimeout> + <*RPCs_own_timeout> is expired
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("test_scripts/Defects/4_5/1880/common")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local params_with_timeout = {
  interactionMode = "MANUAL_ONLY",
  timeout = 8000
}
local params_without_timeout = {
  interactionMode = "MANUAL_ONLY"
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerNoPTU)
runner.Step("Activate App", common.activate)
runner.Step("CreateInteractionChoiceSet", common.createInteractionChoiceSet)

runner.Title("Test")
runner.Step("PerformInteraction_default_timeout_and_PI_timeout_with_VR_response", common.performInteraction,
  { params_with_timeout, common.notSendUIresp, common.sendVRresp, common.noAdditionalTimeout })
runner.Step("PerformInteraction_default_timeout_and_PI_default_timeout_with_VR_response", common.performInteraction,
  { params_without_timeout, common.notSendUIresp, common.sendVRresp, common.noAdditionalTimeout })
runner.Step("PerformInteraction_default_timeout_and_PI_timeout", common.performInteraction,
  { params_with_timeout, common.notSendUIresp, common.notSsendVRresp, common.noAdditionalTimeout })
runner.Step("PerformInteraction_default_timeout_and_PI_default_timeout", common.performInteraction,
  { params_without_timeout, common.notSendUIresp, common.notSsendVRresp, common.noAdditionalTimeout })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
