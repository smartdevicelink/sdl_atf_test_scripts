---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL restored Widget window to NONE level after IGN_OFF/IGN_ON cycle
-- in case of multiiple widgets
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated (FULL level)
-- 4) App successfully created 3 widget windows
-- 5) Widgets are activated on the HMI and has FULL level
-- Steps:
-- 1) IGN_OFF/IGN_ON cycle is performed
-- 2) App re-register with actual HashId
-- SDL does:
--  - send UI.CreateWindow(params) request to HMI 3 times
-- 3) HMI sends valid UI.CreateWindow response to SDL for each request
-- SDL does:
--  - not send CreateWindow response to app
--  - send OnHMIStatus (FULL level) notification for Main window to app
--  - send OnHMIStatus (NONE level) notification for each Widget window to app
-- 4) HMI sends valid BC.OnSystemCapabilityUpdated notification to SDL for each widget window (+ main)
-- SDL does:
--  - accumulate all 4 notifications (3 widgets + main)
--  - send one notification to mobile app with information about 4 windows
-- 5) Each widget is activated on the HMI and has FULL level
-- 6) App send Show(with WindowID for Widget window) request to SDL
-- SDL does:
--  - proceed with request as normal (SUCCESS or not depending on HMI response)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local widgets = {
  [1] = {
    windowID = 1,
    windowName = "Name_1",
    type = "WIDGET"
  },
  [2] = {
    windowID = 2,
    windowName = "Name_2",
    type = "WIDGET",
    associatedServiceType = "MEDIA",
    duplicateUpdatesFromWindowID = 1
  },
  [3] = {
    windowID = 3,
    windowName = "Name_3",
    type = "WIDGET",
    associatedServiceType = "NAVIGATION",
    duplicateUpdatesFromWindowID = 2
  }
}

--[[ Local Functions ]]
local function createWindow(pParams, pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.setHashId(data.payload.hashID, pAppId)
    end)
  common.createWindow(pParams, pAppId)
end

local function checkResumption(pWidgetParams, pAppId)
  local function getAllWindowIds()
    local out = { 0 }
    for _, widgetParam in ipairs(pWidgetParams) do
      table.insert(out, widgetParam.windowID)
    end
    return out
  end
  local windowIds = getAllWindowIds(pWidgetParams)
  local winCaps = common.getOnSCUParams(windowIds)
  common.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated", winCaps)
  common.getHMIConnection():ExpectRequest("UI.CreateWindow", pWidgetParams[1], pWidgetParams[2], pWidgetParams[3])
  :Do(function(e, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      common.sendOnSCU(common.getOnSCUParams(windowIds, e.occurences), pAppId)
    end)
  :Times(3)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { windowID = 0, hmiLevel = "NONE" },
    { windowID = pWidgetParams[1].windowID, hmiLevel = "NONE" },
    { windowID = pWidgetParams[2].windowID, hmiLevel = "NONE" },
    { windowID = pWidgetParams[3].windowID, hmiLevel = "NONE" },
    { windowID = 0, hmiLevel = "FULL" })
  :Times(5)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
for i = 1, 3 do
  common.Step("App create Widget " .. i, createWindow, { widgets[i] })
  common.Step("Widget " .. i .. " is activated", common.activateWidgetFromNoneToFULL,
    { widgets[i].windowID })
end

common.Title("Test")
common.Step("IGNITION_OFF", common.ignitionOff)
common.Step("IGNITION_ON", common.start)
common.Step("Re-register App resumption data", common.reRegisterAppSuccess,
  { widgets, 1, checkResumption })
for i = 1, 3 do
  common.Step("Widget " .. i .. " is activated after restore", common.activateWidgetFromNoneToFULL,
    { widgets[i].windowID })
end
common.Step("Show RPC to widget 1 SUCCESS", common.sendShowToWindow,
  { widgets[1].windowID })
common.Step("Show RPC to Widget 2 with duplicate ID unsuccess",
  common.sendShowToWindowUnsuccessHMIREJECTED, { widgets[2].windowID })
common.Step("Show RPC to Widget 3 with duplicate ID unsuccess",
  common.sendShowToWindowUnsuccessHMIREJECTED, { widgets[3].windowID })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
