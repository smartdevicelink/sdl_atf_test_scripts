---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app is activated into FULL level in case if user taps on a soft button
-- in the widget with .systemAction = STEAL_FOCUS
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) App successfully created a widget
-- 4) Widget is activated in the HMI
-- 5) App send Show(with WindowID for widget window) request to SDL
-- Steps:
-- 1) HMI sends two OnButtonEvent and OnButtonPress notifications for "STEAL_FOCUS" button
-- 2) HMI sends BC.OnAppActivated notification with the main's window ID to SDL
-- SDL does:
-- send OnHMIStatus notification for the main window (hmiLevel: FULL) to app
-- 3) App changes HMI level from FULL to LIMITED
-- 4) HMI sends two OnButtonEvent and OnButtonPress notifications for "STEAL_FOCUS" button
-- 5) HMI sends BC.OnAppActivated notification with the main's window ID to SDL
-- SDL does:
-- send OnHMIStatus notification for the main window (hmiLevel: FULL) to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 3,
  windowName = "Widget",
  type = "WIDGET"
}

local pMainId = 0

function common.getShowParams()
  return  {
    requestShowParams = {
      windowID = params.windowID,
      softButtons = {
        {
          type = "TEXT",
          text = config.application1.registerAppInterfaceParams.appName,
          softButtonID = 5,
          systemAction = "STEAL_FOCUS"
        }
      }
    },
    requestShowUiParams = {
      windowID = params.windowID,
      softButtons = {
        {
          type = "TEXT",
          text = config.application1.registerAppInterfaceParams.appName,
          softButtonID = 5,
          systemAction = "STEAL_FOCUS"
        }
      }
    }
  }
end

local function buttonPress(pAppId)
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", appID = common.getHMIAppId(pAppId) },
    { name = "CUSTOM_BUTTON", mode = "BUTTONUP", appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = "CUSTOM_BUTTON", mode = "SHORT", appID = common.getHMIAppId(pAppId) })
end

local function activateAppViaStealFocusButton_NONE_FULL(pAppId)
  if not pAppId then pAppId = 1 end
  buttonPress(pAppId)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", windowID = pMainId },
    { hmiLevel = "FULL", windowID = params.windowID }) -- is sent for widget window since Audio/Video state has changed
  :Times(2)
  common.wait()
end

local function activateAppViaStealFocusButton_LIMITED_FULL(pAppId)
  if not pAppId then pAppId = 1 end
  buttonPress(pAppId)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", windowID = pMainId })
  common.wait()
end

local function deactivateApp_FULL_LIMITED(pAppId)
  if not pAppId then pAppId = 1 end
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId(pAppId), windowID = pMainId })
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED", windowID = pMainId })
  common.wait()
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Success create Widget window", common.createWindow, { params })
common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { params.windowID, 1 })
common.Step("App sends Show RPC to widget window", common.sendShowToWindow, { params.windowID })

common.Title("Test")
common.Step("App activation from NONE to FULL via STEAL_FOCUS button", activateAppViaStealFocusButton_NONE_FULL)
common.Step("App deactivate from FULL to LIMITED", deactivateApp_FULL_LIMITED)
common.Step("App activation from LIMITED to FULL via STEAL_FOCUS button", activateAppViaStealFocusButton_LIMITED_FULL)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
