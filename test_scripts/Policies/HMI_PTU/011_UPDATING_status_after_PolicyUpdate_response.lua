---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md

-- Description: Check that SDL.OnStatusUpdate(UPDATING) is sent only after successful BC.PolicyUpdate response

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
--   a) send SDL.OnStatusUpdate(UPDATING) notification to the HMI after receiving BC.PolicyUpdate response
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local actualResponseSendingTime
local responseTime = 3000

--[[ Local Functions ]]
local function registerApp()
  common.registerNoPTU()
  common.hmi():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" })
  :ValidIf(function(_, data)
      if data.params.status == "UPDATING" then
        local updatingNotificationTime = timestamp()
        local timeBetweenResNot = updatingNotificationTime - actualResponseSendingTime

        if timeBetweenResNot < 0 and timeBetweenResNot > 200 then
          return false, "UPDATING notification is not received right after BC.PolicyUpdate response.\n"
            .. "Actual time is " .. timeBetweenResNot
        end
        return true
      end
      return true
    end)
  :Times(2)

  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
    :Do(function(_, data)
        actualResponseSendingTime = timestamp()
        local function response()
          common.hmi():SendResponse(data.id, data.method, "SUCCESS", { })
        end
        RUN_AFTER(response, responseTime)
      end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("RAI with BC.PolicyUpdate delayed response", registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
