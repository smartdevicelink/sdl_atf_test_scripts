---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
--
-- Description: Check that if the first PTU via HMI was performed for App1, the second PTU via HMI
-- will be performed successfully after registration of the App2
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. App1 is registered
-- 3. PTU via HMI for the App1 was performed successfully
-- 4. App2 is registered
--
-- Steps:
-- 1) The second PTU is triggered
-- SDL does:
--   a) send SDL.OnStatusUpdate(UPDATE_NEEDED) notification to the HMI,
--   b) create the PTS,
--   c) send BC.PolicyUpdate request to the HMI
-- 2) HMI sends BC.PolicyUpdate response with resultCode "SUCCESS" to the SDL
-- SDL does:
--   a) send SDL.OnStatusUpdate(UPDATING) notification to the HMI
-- 3) HMI requests endpoints for service 7 by sending GetPolicyConfigurationData RPC to the SDL
-- SDL does:
--   a) send GetPolicyConfigurationData response with endpoints for requested service 7
-- 4) HMI decodes the file received from the policy server successfully and
--    sends OnReceivedPolicyUpdate notification to the SDL
-- SDL does:
--   a) check that PTU is correct and send SDL.OnStatusUpdate(UP_TO_DATE) notification to the HMI
--   b) send OnPermissionsChange notification to the App1 and to the App2
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
runner.Step("PTU via HMI", common.ptuViaHMI)
runner.Step("Register App2", common.registerApp, { appSessionId2 })

runner.Title("Test")
runner.Step("Second PTU via HMI", common.ptuViaHMI, { common.PTUfuncWithNewGroup })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
