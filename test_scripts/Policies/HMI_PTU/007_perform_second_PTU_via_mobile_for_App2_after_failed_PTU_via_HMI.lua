---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
--
-- Description: Check that the second PTU via mobile app2 after the failed attempt via HMI for the App2 will be
-- performed successfully
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. App1 is registered
-- 3. PTU via mobile App1 was performed successfully
-- 4. App2 is registered
--
-- Steps:
-- 1) PTU via HMI is triggered
-- SDL does:
--   a) send SDL.OnStatusUpdate(UPDATE_NEEDED) notification to the HMI
--   b) create the PTS
--   c) send BC.PolicyUpdate request to the HMI
-- 2) HMI sends BC.PolicyUpdate response with resultCode "SUCCESS" to the SDL
-- SDL does:
--   a) send SDL.OnStatusUpdate(UPDATING) notification to the HMI
-- 3) HMI requests with endpoints for the service 7 by sending GetPolicyConfigurationData rpc to the SDL
-- SDL does:
--   a) send GetPolicyConfigurationData response with endpoints for the requested service 7
-- 4) PTU is triggered via a mobile app in case of failed attempt via HMI
-- 5) HMI sends BC.OnSystemRequest notification without appId to the SDL
-- SDL does:
--   a) send OnSystemRequest notification to the App2
-- 6) App2 gets PTU file and sends SystemRequest request with the file to the SDL
-- SDL does:
--   a) send BC.SystemRequest to the HMI
-- 7) HMI sends BC.SystemRequest response to the SDL
-- SDL does:
--   a) resend successful SystemRequest response to the App2
-- 8) HMI decodes the file received from the policy server successfully
--    and sends OnReceivedPolicyUpdate notification to the SDL
-- SDL does:
--   a) check that PTU is correct and send SDL.OnStatusUpdate(UP_TO_DATE) notification to the HMI
--   b) send OnPermissionsChange notifications to the App1 and to the App2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerApp, { appSessionId1 })
runner.Step("Activate App1", common.activateApp, { appSessionId1 })
runner.Step("PTU via HMI", common.ptuViaHMI)
runner.Step("Register App2", common.registerApp, { appSessionId2 })
runner.Step("Activate App2", common.activateApp, { appSessionId2 })

runner.Title("Test")
runner.Step("Unsuccessful PTU via HMI", common.unsuccessfulPTUviaHMI)
runner.Step("Successful PTU via mobile App2", common.policyTableUpdate)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
