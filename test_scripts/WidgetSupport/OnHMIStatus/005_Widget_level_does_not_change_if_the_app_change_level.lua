---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check widget's level does not depend on the changes of app's level
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered
-- 4) App created a widget
-- 5) Widget is activated on the HMI and has FULL level
-- Step:
-- 1) App changes HMI level
--  a. from NONE to FULL
--  b. from FULL to LIMITED
--  c. from LIMITED to BACKGROUND
--  d. from BACKGROUND to LIMITED
--  f. from LIMITED to FULL
--  g. from FULL to NONE
-- SDL does:
--  - send 2 OnHMIStatus notification for main and widget windows to app (transitions a, c, d, g)
--    audio/videoStreamingState is changed
--  - send 1 OnHMIStatus notification for main window to app (transitions b, f)
--    audio/videoStreamingState is not changed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = "Name",
  type = "WIDGET"
}

local pMainId = 0

--[[ Local Functions ]]
local function activateAppFromNoneToFull()
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", windowID = pMainId, audioStreamingState = "AUDIBLE" },
    { hmiLevel = "FULL", windowID = params.windowID, audioStreamingState = "AUDIBLE" })
  :Times(2)
end

local function deactivateAppFromFullToLimited()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
  { appID = common.getHMIAppId(), windowID = pMainId })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", windowID = pMainId, audioStreamingState = "AUDIBLE" })
  common.wait()
end

local function deactivateAppFromLimitedToBackground()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
  { eventName = "DEACTIVATE_HMI", isActive = true })

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", windowID = pMainId, audioStreamingState = "NOT_AUDIBLE" },
    { hmiLevel = "FULL", windowID = params.windowID, audioStreamingState = "NOT_AUDIBLE" })
  :Times(2)
end

local function activateAppFromBackgroundToLimited()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
  { eventName = "DEACTIVATE_HMI", isActive = false })

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", windowID = pMainId, audioStreamingState = "AUDIBLE" },
    { hmiLevel = "FULL", windowID = params.windowID, audioStreamingState = "AUDIBLE" })
  :Times(2)
end

local function activateAppFromLimitedToFull()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppActivated",
  { appID = common.getHMIAppId(), windowID = pMainId })
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", windowID = pMainId, audioStreamingState = "AUDIBLE" })
  common.wait()
end

local function deactivateAppFromFullToNone()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
  { appID = common.getHMIAppId(), reason = "USER_EXIT" })

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", windowID = pMainId, audioStreamingState = "NOT_AUDIBLE" },
    { hmiLevel = "FULL", windowID = params.windowID, audioStreamingState = "NOT_AUDIBLE" })
  :Times(2)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App create a widget", common.createWindow, { params })
common.Step("Widget is activated on the HMI", common.activateWidgetFromNoneToFULL, { params.windowID })

common.Title("Test")
common.Step("App activated from NONE to FULL", activateAppFromNoneToFull)
common.Step("App deactivated from FULL to LIMITED", deactivateAppFromFullToLimited)
common.Step("App deactivated from LIMITED to BACKGROUND", deactivateAppFromLimitedToBackground)
common.Step("App activated from BACKGROUND to LIMITED", activateAppFromBackgroundToLimited)
common.Step("App activated from LIMITED to FULL", activateAppFromLimitedToFull)
common.Step("App deactivated from FULL to NONE", deactivateAppFromFullToNone)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
