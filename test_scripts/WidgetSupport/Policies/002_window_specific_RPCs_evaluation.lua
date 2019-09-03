---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check window specific RPCs are evaluated against HMI level of targeting window
--
-- Preconditions:
-- 1) "Show" RPC is allowed in FULL level and disallowed in NONE in Policy DB
-- 2) SDL and HMI are started, App is registered
-- 3) App created a widget
-- Steps:
-- 1) App sends Show requests to main and widget windows
-- SDL does respond "DISALLOWED" to app for both requests (main and widget windows are in NONE)
-- 2) Widget window is activated (NONE to FULL)
-- 3) App sends Show requests to main and widget windows
-- SDL does respond "DISALLOWED" to app for main window and "SUCCESS" for widget window
-- 4) App is activated (NONE to FULL)
-- 5) App sends Show requests to main and widget windows
-- SDL does respond "SUCCESS" to app for both requests (main and widget windows are in FULL)
-- 6) Widget window is deactivated (FULL to NONE)
-- 7) App sends Show requests to main and widget windows
-- SDL does respond "SUCCESS" to app for main window and "DISALLOWED" for widget window
-- 8) App is deactivated (FULL to NONE)
-- 9) App sends Show requests to main and widget windows
-- SDL does respond "DISALLOWED" to app for both requests (main and widget windows are in NONE)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local widgetId = 1

--[[ Local Functions ]]
local function activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", systemContext = "MAIN" })
  :Times(2)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App creates a widget", common.createWindow,
  { { windowID = widgetId, windowName = "Widget" .. widgetId, type = "WIDGET" } })

common.Title("Test")
common.Title("App:NONE, Widget:NONE - Main:DISALLOWED, Widget:DISALLOWED")
common.Step("App sends Show to main DISALLOWED", common.sendShowToWindowUnsuccess,
  { nil, "DISALLOWED" })
common.Step("App sends Show to widget DISALLOWED", common.sendShowToWindowUnsuccess,
  { widgetId, "DISALLOWED" })

common.Title("App:NONE, Widget:FULL - Main:DISALLOWED, Widget:SUCCESS")
common.Step("Activate Widget to FULL", common.activateWidgetFromNoneToFULL, { widgetId })
common.Step("App sends Show to main DISALLOWED", common.sendShowToWindowUnsuccess,
  { nil, "DISALLOWED" })
common.Step("App sends Show to widget SUCCESS", common.sendShowToWindow,
  { widgetId })

common.Title("App:FULL, Widget:FULL - Main:SUCCESS, Widget:SUCCESS")
common.Step("Activate App to FULL", activateApp)
common.Step("App sends Show to main SUCCESS", common.sendShowToWindow,
  { nil })
common.Step("App sends Show to widget SUCCESS", common.sendShowToWindow,
  { widgetId })

common.Title("App:FULL, Widget:NONE - Main:SUCCESS, Widget:DISALLOWED")
common.Step("Deactivate Widget to NONE", common.deactivateWidgetFromFullToNone, { widgetId })
common.Step("App sends Show to main SUCCESS", common.sendShowToWindow,
  { nil })
common.Step("App sends Show to widget DISALLOWED", common.sendShowToWindowUnsuccess,
  { widgetId, "DISALLOWED" })

common.Title("App:NONE, Widget:NONE - Main:DISALLOWED, Widget:DISALLOWED")
common.Step("Deactivate App to NONE", common.deactivateAppFromFullToNone)
common.Step("App sends Show to main DISALLOWED", common.sendShowToWindowUnsuccess,
  { nil, "DISALLOWED" })
common.Step("App sends Show to widget DISALLOWED", common.sendShowToWindowUnsuccess,
  { widgetId, "DISALLOWED" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
