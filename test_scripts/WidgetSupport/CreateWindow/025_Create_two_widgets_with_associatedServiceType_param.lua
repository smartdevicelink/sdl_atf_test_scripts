---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL allows only one widget with the same value for 'associatedServiceType' param
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow is allowed by policies
-- 3) App is registered and activated
-- Step:
-- 1) App successfully creates a widget with 'associatedServiceType' parameter via new RPC CreateWindow
-- 2) App tries to create another widget with the same value of 'associatedServiceType' parameter
-- SDL does:
--  - not send UI.CreateWindow(params) request to HMI
--  - send CreateWindow response with success:false, resultCode: "REJECTED" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params1 = {
  windowID = 2,
  windowName = "Widget1",
  type = "WIDGET",
  associatedServiceType = "MEDIA"
}

local params2 = {
  windowID = 3,
  windowName = "Widget2",
  type = "WIDGET",
  associatedServiceType = "MEDIA"
}

local params3 = {
  windowID = 4,
  windowName = "Widget3",
  type = "WIDGET",
  associatedServiceType = "NAVI"
}

local params4 = {
  windowID = 5,
  windowName = "Widget4",
  type = "WIDGET",
  associatedServiceType = "NAVI"
}

--[[ Local Functions ]]
local getOnSystemCapabilityParams_Orig = common.getOnSystemCapabilityParams
function common.getOnSystemCapabilityParams()
  return getOnSystemCapabilityParams_Orig(2)
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
common.Step("App tries to create 1st MEDIA widgget SUCCESS", common.createWindow, { params1 })
common.Step("App tries to create 2nd MEDIA widgget REJECTED", common.createWindowUnsuccess, { params2, "REJECTED" })
common.Step("App tries to create 1st NAVI SUCCESS", common.createWindow, { params3 })
common.Step("App tries to create 2nd NAVI REJECTED", common.createWindowUnsuccess, { params4, "REJECTED" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
