---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check all RPCs (except window specific RPCs) are evaluated against HMI level of the main window
--
-- Preconditions:
-- 1) "AddSubMenu" RPC is allowed in FULL level and disallowed in NONE in Policy DB
-- 2) SDL and HMI are started, App is registered
-- 3) App created a widget
-- Steps:
-- 1) App main and widget windows are in NONE
-- 2) App sends AddSubMenu request
-- SDL does respond "DISALLOWED" to app (main window is in NONE)
-- 3) Widget is activated on HMI (NONE to FULL)
-- 4) App sends AddSubMenu request
-- SDL does respond "DISALLOWED" to app (main window is still in NONE)
-- 5) App is activated on HMI (NONE to FULL)
-- 6) App sends AddSubMenu request
-- SDL does proceed with request and respond "SUCCESS" to app (main window is in FULL)
-- 7) App is deactivated on HMI (FULL to NONE)
-- 8) App sends AddSubMenu request
-- SDL does respond "DISALLOWED" to app (main window is in NONE)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local widgetParams = {
  windowID = 1,
  windowName = "Widget1",
  type = "WIDGET"
}

local addSubMenuParams = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive"
}

--[[ Local Functions ]]
local function activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", systemContext = "MAIN" })
  :Times(2)
end

local function sendAddSubMenu_DISALLOWED()
  local cid = common.getMobileSession():SendRPC("AddSubMenu", addSubMenuParams)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

local function sendAddSubMenu_SUCCESS()
  local cid = common.getMobileSession():SendRPC("AddSubMenu", addSubMenuParams)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App creates a widget", common.createWindow, { widgetParams })

common.Title("Test")
common.Step("App sends AddSubMenu DISALLOWED", sendAddSubMenu_DISALLOWED)
common.Step("Activate Widget to FULL", common.activateWidgetFromNoneToFULL, { widgetParams.windowID })
common.Step("App sends AddSubMenu DISALLOWED", sendAddSubMenu_DISALLOWED)
common.Step("Activate App to FULL", activateApp)
common.Step("App sends AddSubMenu SUCCESS", sendAddSubMenu_SUCCESS)
common.Step("Deactivate App to NONE", common.deactivateAppFromFullToNone)
common.Step("App sends AddSubMenu DISALLOWED", sendAddSubMenu_DISALLOWED)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
