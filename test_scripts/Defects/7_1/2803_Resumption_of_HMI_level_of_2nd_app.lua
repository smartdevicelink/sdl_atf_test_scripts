---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2803
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to resume HMI level of application after unexpected disconnect
--
-- Steps:
-- 1. App_1 is registered and activated (FULL level)
-- 2. IGN_OFF/IGN_ON cycle is performed
-- 3. Wait 35 sec
-- 4. App_1 is registered
-- SDL does:
--  - not resume HMI level App_1
-- 5. App_2 is registered and activated (FULL level)
-- 6. Unexpected disconnect and reconnect are performed
-- SDL does:
--  - resume HMI level of App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local color = require("user_modules/consts").color
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ignitionOff()
  local isOnSDLCloseSent = false
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  utils.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then utils.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, common.mobile.getAppsCount() do
      common.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(common.mobile.getAppsCount())
  common.mobile.disconnect()
  utils.wait(1000)
end

local function checkAbsenceOfHMILevelResumption(pAppId)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  :Times(0)
  utils.wait(5000)
end

local function checkPresenceHMILevelResumption(pAppId)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App 1", common.app.registerNoPTU, { 1 })
runner.Step("Activate App 1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("Ignition Off", ignitionOff)
runner.Step("Ignition On", common.start)

runner.Step("Wait 35 s", utils.wait, { 35000 })
runner.Step("Register App 1", common.app.registerNoPTU, { 1 })
runner.Step("Check No HMI level resumption", checkAbsenceOfHMILevelResumption, { 1 })

runner.Step("Register App 2", common.app.registerNoPTU, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Connect mobile", common.mobile.connect)
runner.Step("Register App 2", common.app.registerNoPTU, { 2 })
runner.Step("Check Yes HMI level resumption", checkPresenceHMILevelResumption, { 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
