---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL restored Main window to FULL level after unexpected disconnect
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered and activated (FULL level)
-- Steps:
-- 1) Unexpected disconnect and reconnect are performed
-- 2) App re-register with actual HashId
-- SDL does:
--  - does not send UI.CreateWindow(params) request to HMI
--  - does not send CreateWindow response to app
-- 3) HMI sends OnSystemCapabilityUpdated(params) notification to SDL
-- SDL does:
--  - send OnSystemCapabilityUpdated(params) notification to app
--  - send OnHMIStatus (FULL level) notification for Main window to app
-- 4) Widget is activated on the HMI and has FULL level
-- 5) App send Show(with WindowID for Main window) request to SDL
-- SDL does:
--  - send request UI.Show(with WindowID for Main window) to HMI
-- 6) HMI sends UI.Show response "SUCCESS"
-- SDL does:
--  - send Show response with (success: true resultCode: "SUCCESS") to App
--  - not send OnSystemCapabilityUpdated notification to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Functions ]]
local function checkResumption()
  local winCaps = common.getOnSCUParams({ 0 })
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", winCaps)
  common.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Times(0)
  common.expCreateWindowResponse()
  :Times(0)
end

local function checkResumption_FULL()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { windowID = 0, hmiLevel = "NONE" },
    { windowID = 0, hmiLevel = "FULL" })
  :Times(2)
  checkResumption()
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App resumption data", common.reRegisterAppSuccess,
  { nil, 1, checkResumption_FULL })
common.Step("Show RPC to Main window", common.sendShowToWindow, { 0 })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
