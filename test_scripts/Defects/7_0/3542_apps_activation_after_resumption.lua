---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3542
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. There are 2 MEDIA apps registered: App_1 and App_2
-- 2. App_1 is in 'LIMITED' and App_2 is in 'BACKGROUND' HMI levels
-- 3. Unexpected disconnect and reconnect are performed
-- 4. SDL resumed HMI level of both apps:
--  - App_1 is in 'LIMITED', App_2 is in 'BACKGROUND' HMI levels
-- 5. App_2 activated
-- 6. App_1 activated
--
-- SDL does:
--  - change HMI level to 'FULL' for App_1
--  - change HMI level to 'BACKGROUND' for App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Apps Configuration ]]
common.getConfigAppParams(1).appHMIType = { "MEDIA" }
common.getConfigAppParams(2).appHMIType = { "MEDIA" }

-- [[ Local Functions ]]
local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(common.mobile.getAppsCount())
  common.mobile.disconnect()
  common.run.wait(1000)
end

local function startSession(pAppId)
   common.getMobileSession(pAppId):StartRPC()
end

local function activateApp(pAppId)
  local secondAppId = pAppId == 1 and 2 or 1
  local cid = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(cid)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
  common.getMobileSession(secondAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "BACKGROUND" })
end

local function deactivateApp(pAppId)
  local secondAppId = pAppId == 1 and 2 or 1
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId(pAppId) })
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED" })
  common.getMobileSession(secondAppId):ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function reRegisterApps()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Times(2)
  local cid1 = common.getMobileSession(1):SendRPC("RegisterAppInterface", common.getConfigAppParams(1))
  common.getMobileSession(1):ExpectResponse(cid1, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      common.getMobileSession(1):ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" }, { hmiLevel = "LIMITED" })
      :Times(2)
      local cid2 = common.getMobileSession(2):SendRPC("RegisterAppInterface", common.getConfigAppParams(2))
      common.getMobileSession(2):ExpectResponse(cid2, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession(2):ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" })
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App 1", common.registerAppWOPTU, { 1 })
runner.Step("Register App 2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })
runner.Step("Activate App 1", common.activateApp, { 1 })
runner.Step("Deactivate App 1", deactivateApp, { 1 })

runner.Title("Test")
runner.Step("Disconnect mobile", unexpectedDisconnect)
runner.Step("Connect mobile", common.mobile.connect)
runner.Step("Start session for App 1", startSession, { 1 })
runner.Step("Start session for App 2", startSession, { 2 })
runner.Step("Re-register Apps", reRegisterApps)
runner.Step("Activate App 2", activateApp, { 2 })
runner.Step("Activate App 1", activateApp, { 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
