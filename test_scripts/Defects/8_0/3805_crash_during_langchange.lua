---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3805
---------------------------------------------------------------------------------------------------
-- Description: A crash occurs during registration
--
-- Steps:
-- 1. Connect EN-US apps
-- 2. Change UI and TTS language to FR-CA
-- 3. Quickly register 5 apps and then unregister them
-- SDL does:
--  - not crash
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

--[[ Local Functions ]]
local function registerApp(pAppId)
    --local session = common.mobile.createSession(pAppId, 1)
    local session = common.getMobileSession(pAppId, 1)
    session:StartService(7)
    :Do(function()
        local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(pAppId))
        common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
          { application = { appName = common.app.getParams(pAppId).appName } })
        :Do(function(_, d1)
            common.app.setHMIId(d1.params.application.appID, pAppId)
          end)
        session:ExpectResponse(corId, { success = true })
        :Do(function()
            session:ExpectNotification("OnHMIStatus",
              { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
            session:ExpectNotification("OnPermissionsChange")
            :Times(AnyNumber())
          end)
      end)
  end

local function changeHMILanguage(lang)
  local hmi = common.hmi.getConnection()
  hmi:SendNotification("UI.OnLanguageChange", { language = lang })
  hmi:SendNotification("TTS.OnLanguageChange", { language = lang })
end

local function registerAllApps()
  for i = 1,5 do
    common.getMobileSession(i, 1):SendRPC("RegisterAppInterface", common.app.getParams(i))
  end
  utils.wait(500)
  for j = 1,5 do
    common.getMobileSession(j):SendRPC("UnregisterAppInterface", {})
  end
end

local function checkCrashed()
  if not common.sdl.isRunning() then common.run.fail("SDL crashed") end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI", common.start)
runner.Step("Register App 1", registerApp, { 1 })
runner.Step("Register App 2", registerApp, { 2 })
runner.Step("Register App 3", registerApp, { 3 })
runner.Step("Register App 4", registerApp, { 4 })
runner.Step("Register App 5", registerApp, { 5 })
runner.Step("Change Language to FR-CA", changeHMILanguage, { "FR-CA" })

runner.Title("Test")
runner.Step("Re-register all apps", registerAllApps)
runner.Step("Check SDL Core status", checkCrashed)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
