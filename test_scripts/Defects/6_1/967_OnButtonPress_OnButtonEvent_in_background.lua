---------------------------------------------------------------------------------------------
-- GitHub issue https://github.com/SmartDeviceLink/sdl_core/issues/967
---------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. Core, HMI started.
-- 2. App is registered on HMI and has HMI level BACKGROUND

-- Steps to reproduce:
-- 1. Send from HMI OnButtonEvent(CUSTOM_BUTTON, SHORT/LONG)

-- Expected result:
-- SDL resend it to BACKGROUND App.
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

local showRequestParams = {
  mainField1 = "mainField1",
  softButtons = {
    {
      type = "TEXT",
      text = "Button1",
      softButtonID = 1,
      systemAction = "DEFAULT_ACTION",
    },
    {
      type = "TEXT",
      text = "Button2",
      softButtonID = 2,
      systemAction = "DEFAULT_ACTION"
    }
  }
}

local pressMode = { "SHORT", "LONG" }

--[[ Local Functions ]]
local function Show()
  local cid = common.getMobileSession():SendRPC("Show", showRequestParams)
  EXPECT_HMICALL("UI.Show", { softButtons =  showRequestParams.softButtons})
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function OnButtonEventPress(pBtnId, pPressMode)
  local btnName = "CUSTOM_BUTTON"
  local hmiAppId = common.getHMIAppId()
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    {
      name = btnName,
      mode = "BUTTONDOWN",
      customButtonID = pBtnId,
      appID = hmiAppId
    })
  common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    {
      name = btnName,
      mode = "BUTTONUP",
      customButtonID = pBtnId,
      appID = hmiAppId
    })
  common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    {
      name = btnName,
      mode = pPressMode,
      customButtonID = pBtnId,
      appID = hmiAppId
    })
  common.getMobileSession():ExpectNotification("OnButtonEvent",
    { buttonName = btnName, buttonEventMode = "BUTTONDOWN", customButtonID = pBtnId},
    { buttonName = btnName, buttonEventMode = "BUTTONUP", customButtonID = pBtnId })
  :Times(2)
  common.getMobileSession():ExpectNotification("OnButtonPress",
    { buttonName = btnName, buttonPressMode = pPressMode, customButtonID = pBtnId})
end

local function deactivateAppToLimited()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function deactivateAppToBackground()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { isActive = true, eventName = "AUDIO_SOURCE" })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Show", Show)

runner.Title("Test")
for _, value in pairs(pressMode) do
  runner.Step("OnButtonEventPress in FULL level with mode " .. value, OnButtonEventPress, { 1, value })
end
runner.Step("Bring app App to LIMITED", deactivateAppToLimited)
for _, value in pairs(pressMode) do
  runner.Step("OnButtonEventPress in LIMITED level with mode " .. value, OnButtonEventPress, { 1, value })
end
runner.Step("Bring app App to BACKGROUND", deactivateAppToBackground)
for _, value in pairs(pressMode) do
  runner.Step("OnButtonEventPress in BACKGROUND level with mode " .. value, OnButtonEventPress, { 1, value })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
