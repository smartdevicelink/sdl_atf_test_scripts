---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3783
---------------------------------------------------------------------------------------------------
-- Description: A crash occurs during registration (occurance: about 1%)
--
-- Steps:
-- 1. Change VR language to FR-CA
-- 2. Connect EN-US apps
-- 4. Quickly register 5 apps and then unregister them
-- 3. Change VR language to FR-CA
-- 4. Quickly register 5 apps and then unregister them
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

local function changeHMILanguage(iface, lang)
  local hmi = common.hmi.getConnection()
  hmi:SendNotification(iface .. ".OnLanguageChange", { language = lang })
  utils.wait(500)
end

local function registerAllApps()
  for i = 1,5 do
    common.getMobileSession(i, 1):SendRPC("RegisterAppInterface", common.app.getParams(i))
  end
  utils.wait(250)
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
runner.Step("Change UI Language to FR-CA", changeHMILanguage, { "UI", "FR-CA" })
runner.Step("Register App 1", registerApp, { 1 })
runner.Step("Register App 2", registerApp, { 2 })
runner.Step("Register App 3", registerApp, { 3 })
runner.Step("Register App 4", registerApp, { 4 })
runner.Step("Register App 5", registerApp, { 5 })

runner.Title("Test")
runner.Step("Re-register all apps", registerAllApps)
runner.Step("Change VR Language to FR-CA", changeHMILanguage, { "VR", "FR-CA" })
runner.Step("Re-register all apps", registerAllApps)
runner.Step("Check SDL Core status", checkCrashed)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
