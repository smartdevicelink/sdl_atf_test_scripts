--------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/842

-- Pre-conditions:
-- 1. SDL is started (EnablePolicy = false)
-- 2. HMI is started

-- Steps to reproduce:
-- 1. Activate App

-- Expected:
-- The application was activated.
--------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hmiAppId

--[[ Local Functions ]]
local function disablePolicy()
  common.setSDLIniParameter("EnablePolicy", "false")
end

local function registerApp()
  common.getMobileSession():StartService(7)
  :Do(function()
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      :Do(function(_, d1)
          hmiAppId = d1.params.application.appID
        end)
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    end)
end

local function activateApp()
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = hmiAppId })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession():ExpectNotification("OnHMIStatus", {
    hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Disabling Policy", disablePolicy)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", registerApp)

runner.Title("Test")
runner.Step("Activate App", activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
