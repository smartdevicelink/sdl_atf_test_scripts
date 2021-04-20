---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md

-- Description: Check that SDL does not send SDL.OnStatusUpdate(UPDATING) in case
--   HMI does not respond to BC.PolicyUpdate request

-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- Steps:
-- 1) PTU via HMI is triggered
-- SDL does:
--   a) send SDL.OnStatusUpdate(UPDATE_NEEDED) notification to the HMI
--   b) create the PTS
--   c) send BC.PolicyUpdate request to the HMI
-- 2) HMI does not send BC.PolicyUpdate response to the SDL
--SDL does:
--   a) not send SDL.OnStatusUpdate(UPDATING) notification to the HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Functions ]]
local function registerApp()
  common.registerNoPTU()
  common.hmi():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" })
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function()
      -- no response from HMI
    end)
  common.wait(11000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RAI without BC.PolicyUpdate response", registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
