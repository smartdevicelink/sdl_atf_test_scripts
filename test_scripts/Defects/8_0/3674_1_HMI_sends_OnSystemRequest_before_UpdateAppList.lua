---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3674
---------------------------------------------------------------------------------------------------
-- Description: Check SDL suspends sending of OnSystemRequest notifications to mobile App until
-- app HMI state is established
---------------------------------------------------------------------------------------------------
-- In case:
-- 1. App sends RegisterAppInterface
-- 2. HMI receives BC.OnAppRegistered
-- 3. HMI sends OnSystemRequest(PROPRIETARY) notification
-- SDL does:
-- - transfer OnSystemRequest(PROPRIETARY) to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local sysRequestParams = {
  requestType = "PROPRIETARY",
  fileType = "JSON",
  fileName = "sdl_snapshot.json"
}

--[[ Local function ]]
local function OnSystemRequestDuringRAI()
  common.getMobileSession():StartService(7)
  :Do(function()
      common.getMobileSession():ExpectNotification("OnSystemRequest"):Times(2)
      :ValidIf(function (_, data)
          if data.payload.requestType == "PROPRIETARY" or data.payload.requestType == "LOCK_SCREEN_ICON_URL" then
            return true
          else
            return false, "Unexpected OnSystemRequest on mobile"
          end
        end)

      common.getMobileSession():SendRPC("RegisterAppInterface", common.app.getParams())

      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      :Do(function ()
          common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest", sysRequestParams)
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", OnSystemRequestDuringRAI)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
