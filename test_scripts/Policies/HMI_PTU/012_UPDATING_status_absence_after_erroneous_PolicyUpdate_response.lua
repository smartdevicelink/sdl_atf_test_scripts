---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md

-- Description: Check that SDL does not send SDL.OnStatusUpdate(UPDATING) after unsuccessful BC.PolicyUpdate response

-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- Steps:
-- 1) PTU via HMI is triggered
-- SDL does:
--   a) send SDL.OnStatusUpdate(UPDATE_NEEDED) notification to the HMI
--   b) create the PTS
--   c) send BC.PolicyUpdate request to the HMI
-- 2) HMI sends BC.PolicyUpdate response with resultCode "GENERIC_ERROR" to the SDL
--SDL does:
--   a) not send SDL.OnStatusUpdate(UPDATING) notification to the HMI after receiving error BC.PolicyUpdate response
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
    :Do(function(_, data)
        local function response()
          common.hmi():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
        end
        RUN_AFTER(response, 1000)
      end)

  common.wait(3000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RAI with error BC.PolicyUpdate", registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
