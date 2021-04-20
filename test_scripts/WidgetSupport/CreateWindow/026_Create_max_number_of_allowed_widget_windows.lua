---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL validates max number of allowed widget windows
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow is allowed by policies
-- 3) App is registered and activated
-- 4) HMI sends BC.OnSystemCapabilityUpdated notification for main window with 'maximumNumberOfWindows' for WIDGET = 1
-- Step:
-- 1) App successfully creates 1st widget
-- 2) App tries to create 2nd widget
-- SDL does:
--  - not send UI.CreateWindow(params) request to HMI
--  - send CreateWindow response with success:false, resultCode: "REJECTED" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local widgetParams1 = {
  windowID = 2,
  windowName = "Widget1",
  type = "WIDGET"
}

local widgetParams2 = {
  windowID = 3,
  windowName = "Widget2",
  type = "WIDGET"
}

--[[ Local Functions ]]
local getOnSystemCapabilityParams_Orig = common.getOnSystemCapabilityParams
function common.getOnSystemCapabilityParams()
  return getOnSystemCapabilityParams_Orig(1)
end

local function sendOnSCU()
  local params = common.getOnSystemCapabilityParams()
  local paramsToSDL = common.cloneTable(params)
  paramsToSDL.appID = common.getHMIAppId()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", params)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("HMI sends OnSCU notification", sendOnSCU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("App tries to create 1st widget SUCCESS", common.createWindow, { widgetParams1 })
common.Step("App tries to create 2nd widget REJECTED", common.createWindowUnsuccess, { widgetParams2, "REJECTED" })
common.Step("App tries to delete 1st widget SUCCESS", common.deleteWindow, { widgetParams1.windowID })
common.Step("App tries to create 2nd widget SUCCESS", common.createWindow, { widgetParams2 })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
