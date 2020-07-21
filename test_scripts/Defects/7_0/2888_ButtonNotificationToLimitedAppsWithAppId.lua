---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2888
-- Use case: OnButtonPress and OnButtonEvent
--
-- Description:
-- Mobile application sends valid SubscribeButton request and gets SubscribeButton "SUCCESS" response from SDL.
-- SDL subscribe the application to get notifications for OnButtonEvent and OnButtonPress of the "ButtonName"

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Limited HMI level

-- Steps:
-- 1. AppID -> SDL: SubscribeButton (<buttonName>)
-- SDL validates and process request
-- SDL -> AppID: SubscribeButton (resultCode:SUCCESS, success: true)
-- SDL -> HMI: OnButtonSubscription (<appID>, <buttonName, isSubscribed:True)
--
-- Expected:
-- SDL resends OnButtonEvent and OnButtonPress notifications to the subscribed mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local buttonName = {
  "OK",
  "SEEKLEFT",
  "SEEKRIGHT",
  "TUNEUP",
  "TUNEDOWN",
  "PRESET_0",
  "PRESET_1",
  "PRESET_2",
  "PRESET_3",
  "PRESET_4",
  "PRESET_5",
  "PRESET_6",
  "PRESET_7",
  "PRESET_8"
}

local buttonPressMode = {
  "SHORT",
  "LONG"
}

--[[ Local Functions ]]
local function subscribeButton(pButName)
  local cid = commonSmoke.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
  local appIDvalue = commonSmoke.getHMIAppId()
  commonSmoke.getHMIConnection():ExpectRequest("Buttons.OnButtonSubscription",
    { appID = appIDvalue, name = pButName, isSubscribed = true })
  commonSmoke.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  commonSmoke.getMobileSession():ExpectNotification("OnHashChange")
end

local function pressButton(pButName, pButtonPressMode)
  local appIDvalue = commonSmoke.getHMIAppId()
  commonSmoke.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButName, mode = "BUTTONDOWN", appID = appIDvalue })
  commonSmoke.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButName, mode = "BUTTONUP", appID = appIDvalue })
  commonSmoke.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = pButName, mode = pButtonPressMode, appID = appIDvalue })

  commonSmoke.getMobileSession():ExpectNotification("OnButtonEvent",
    {buttonName = pButName, buttonEventMode = "BUTTONDOWN"},
    {buttonName = pButName, buttonEventMode = "BUTTONUP"})
  :Times(2)
  commonSmoke.getMobileSession():ExpectNotification("OnButtonPress",
    { buttonName = pButName, buttonPressMode = pButtonPressMode })
  :Timeout(1000)
end

local function changeLevelToLimited()
  local appIDvalue = commonSmoke.getHMIAppId()
  commonSmoke.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = appIDvalue, reason = "GENERAL" })
  commonSmoke.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Change Level To Limited", changeLevelToLimited)

runner.Title("Test")
for _, v in pairs(buttonName) do
  runner.Title("Button " .. v)
  runner.Step("SubscribeButton", subscribeButton, { v })
    for _, y in pairs(buttonPressMode) do
      runner.Step("PressButton " .. y, pressButton, { v, y })
    end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
