---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md

-- Description: Check that PTU is performed via a mobile app after the unsuccessful PTU attempt via HMI

-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- Steps:
-- 1) PTU via HMI is triggered
-- SDL does:
--   a) send SDL.OnStatusUpdate(UPDATE_NEEDED) notification to the HMI
--   b) create the PTS
--   c) send BC.PolicyUpdate request to the HMI
-- 2) HMI sends BC.PolicyUpdate response with resultCode "SUCCESS" to the SDL
--SDL does:
--   a) send SDL.OnStatusUpdate(UPDATING) notification to the HMI
-- 3) HMI requests endpoints for service 7 by sending GetPolicyConfigurationData rpc to the SDL
-- SDL does:
--   a) send GetPolicyConfigurationData response with the endpoints for the requested service 7
-- 4) PTU via HMI fails
-- 5) HMI starts the PTU via a mobile app and sends BC.OnSystemRequest notification to the SDL
-- SDL does:
--   a) send an OnSystemRequest notification to the app
-- 6) App gets PTU file and sends SystemRequest request with received file to the SDL
-- SDL does:
--   a) send BC.SystemRequest to HMI
-- 7) HMI responds successfully to BC.SystemRequest request from SDL
-- SDL does:
--   a) resend successful SystemRequest response the app
-- 8) HMI decodes the received file from policy server successfully and sends OnReceivedPolicyUpdate to the SDL
-- SDL does:
--   a) check that PTU is correct and send SDL.OnStatusUpdate(UP_TO_DATE) notification to the HMI
--   b) send OnPermissionsChange notification to the app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)

runner.Title("Test")
runner.Step("Unsuccessful PTU via a HMI", common.unsuccessfulPTUviaHMI)
runner.Step("Successful PTU via a mobile app", common.policyTableUpdate)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
