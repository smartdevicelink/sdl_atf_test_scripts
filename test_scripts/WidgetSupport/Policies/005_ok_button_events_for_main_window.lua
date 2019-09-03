---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check button events are evaluated against HMI level of appropriate window
-- Case: 'OK' button
--
-- Precondition:
-- 1) 'OnButtonEvent' and 'OnButtonPress' notifications are allowed at 'FULL' HMI level in policies
-- 2) SDL and HMI are started
-- 3) App registered and created one widget
-- 4) App subscribed to 'OK' button
--
-- Steps:
-- 1) HMI level of each window is changed from NONE to FULL and vice versa
-- 2) HMI sends 'OnButtonEvent' and 'OnButtonPress' notifications after each level change
-- SDL does:
--   - transfer notifications to App only in case if main window HMI level is 'FULL'
--   - and doesn't transfer them in opposite case
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local winParams = {
  main = { winId = 0, type = "MAIN", name = "Main" },
  widget1 = { winId = 1, type = "WIDGET", name = "Widget1" },
  widget2 = { winId = 2, type = "WIDGET", name = "Widget2" },
}

local function getWidgetParams(pWindowType)
  return {
    windowID = winParams[pWindowType].winId,
    windowName = winParams[pWindowType].name,
    type = winParams[pWindowType].type
  }
end

local function sendBtnEvent(pEventName, pEventMode, pDelay)
  if not pDelay then pDelay = 0 end
  RUN_AFTER(function()
      common.getHMIConnection():SendNotification("Buttons." .. pEventName, {
        name = "OK",
        mode = pEventMode,
        appID = common.getHMIAppId()
      })
    end, pDelay)
end

local function buttonPress_SUCCESS()
  sendBtnEvent("OnButtonEvent", "BUTTONDOWN", 0)
  sendBtnEvent("OnButtonEvent", "BUTTONUP", 100)
  sendBtnEvent("OnButtonPress", "SHORT", 100)

  common.getMobileSession():ExpectNotification("OnButtonEvent",
    { buttonName = "OK", buttonEventMode = "BUTTONDOWN" },
    { buttonName = "OK", buttonEventMode = "BUTTONUP" })
  :Times(2)
  common.getMobileSession():ExpectNotification("OnButtonPress",
    { buttonName = "OK", buttonPressMode = "SHORT" })
end

local function buttonPress_DISALLOWED()
  sendBtnEvent("OnButtonEvent", "BUTTONDOWN", 0)
  sendBtnEvent("OnButtonEvent", "BUTTONUP", 100)
  sendBtnEvent("OnButtonPress", "SHORT", 100)

  common.getMobileSession():ExpectNotification("OnButtonEvent")
  :Times(0)
  common.getMobileSession():ExpectNotification("OnButtonPress")
  :Times(0)
end

local function activateWindowFromNoneToFull(pWindowType)
  if winParams[pWindowType].type == "MAIN" then
    local cid = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
    common.getHMIConnection():ExpectResponse(cid)
    common.getMobileSession():ExpectNotification("OnHMIStatus")
    :Times(AtLeast(1))
  end
  if winParams[pWindowType].type == "WIDGET" then
    common.activateWidgetFromNoneToFULL(winParams[pWindowType].winId)
  end
end

local function deactivateWindowFromFullToNone(pWindowType)
  if winParams[pWindowType].type == "MAIN" then
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
      { appID = common.getHMIAppId(), reason = "USER_EXIT" })
    common.getMobileSession():ExpectNotification("OnHMIStatus")
    :Times(AtLeast(1))
  end
  if winParams[pWindowType].type == "WIDGET" then
    common.deactivateWidgetFromFullToNone(winParams[pWindowType].winId)
  end
end

local function ptUpdate(pTbl)
  table.insert(pTbl.policy_table.functional_groupings["Base-4"].rpcs["Show"].hmi_levels, "NONE")
  table.insert(pTbl.policy_table.functional_groupings["Base-4"].rpcs["SubscribeButton"].hmi_levels, "NONE")
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "WidgetSupport" }
end

local function subscribeButton(pButName)
  local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
  common.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription",
    { appID = common.getHMIAppId(), name = pButName, isSubscribed = true })
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.setHashId(data.payload.hashID, 1)
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerApp)
common.Step("Policy Table Update allows some RPCs in NONE", common.policyTableUpdate, { ptUpdate })
common.Step("Create Widget window", common.createWindow, { getWidgetParams("widget1") })
common.Step("Subscribe to OK button", subscribeButton, { "OK" })

common.Title("Test")
common.Title("Main: NONE, Widget: NONE")
common.Step("Press button on main DISALLOWED", buttonPress_DISALLOWED)

common.Title("Main: FULL, Widget: NONE")
common.Step("Move main window to FULL", activateWindowFromNoneToFull, { "main" })
common.Step("Press button on main SUCCESS", buttonPress_SUCCESS)

common.Title("Main: FULL, Widget: FULL")
common.Step("Move widget window to FULL", activateWindowFromNoneToFull, { "widget1" })
common.Step("Press button on main SUCCESS", buttonPress_SUCCESS)

common.Title("Main: NONE, Widget: FULL")
common.Step("Move main window to NONE", deactivateWindowFromFullToNone, { "main" })
common.Step("Press button on main DISALLOWED", buttonPress_DISALLOWED)

common.Title("Main: NONE, Widget: NONE")
common.Step("Move widget window to NONE", deactivateWindowFromFullToNone, { "widget1" })
common.Step("Press button on main DISALLOWED", buttonPress_DISALLOWED)

common.Title("Main: NONE, Widget: FULL")
common.Step("Move widget window to FULL", activateWindowFromNoneToFull, { "widget1" })
common.Step("Press button on main DISALLOWED", buttonPress_DISALLOWED)

common.Title("Main: FULL, Widget: FULL")
common.Step("Move main window to FULL", activateWindowFromNoneToFull, { "main" })
common.Step("Press button on main SUCCESS", buttonPress_SUCCESS)

common.Title("Main: FULL, Widget: NONE")
common.Step("Move widget window to NONE", deactivateWindowFromFullToNone, { "widget1" })
common.Step("Press button on main SUCCESS", buttonPress_SUCCESS)

common.Title("Main: NONE, Widget: NONE")
common.Step("Move main window to NONE", deactivateWindowFromFullToNone, { "main" })
common.Step("Press button on main DISALLOWED", buttonPress_DISALLOWED)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
