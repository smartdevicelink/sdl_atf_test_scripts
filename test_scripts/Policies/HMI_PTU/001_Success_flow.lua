---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md

-- Description: Check that PTU is successfully performed via HMI

-- In case:
-- 1. SDL and HMI are started
-- 2. App is registered
-- 3. PTU is triggered
-- SDL does:
--   a) send UPDATE_NEDDED to HMI
--   b) create the snapshot
--   c) send BC.PolicyUpdate request to HMI
-- 4. HMI sends BC.PolicyUpdate response with resultCode "SUCCESS" to the SDL
-- SDL does:
--   a) set PTU status to UPDATING and sends OnStatusUpdate notification to HMI
-- 5. HMI requests endpoints for service 7 sending GetPolicyConfigurationData rpc to the SDL
-- SDL does:
--   a) send GetPolicyConfigurationData response with endpoints for the requested service 7
-- 6. HMI gets the update and sends SDL.OnReceivedPolicyUpdate(<path to file>) to SDL
-- SDL does:
--   a) apply the update and sends OnStatusUpdate(UP_TO_DATE) to HMI
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
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("HMI PTU", common.ptuViaHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
