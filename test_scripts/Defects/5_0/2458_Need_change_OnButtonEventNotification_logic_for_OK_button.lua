---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2458
--
-- Description:
-- 1) Need change OnButtonEventNotification logic for OK button
-- In case:
-- 1) First mobile app is subscribed on "OK" button and with "FULL" HMI Level
-- 2) Second mobile app is subscribed on "OK" button and with "LIMITED" HMI Level
-- SDL does:
-- 1) respond SubscribeButton(SUCCESS) to mobile app1 and app2
-- 2) send OnHashChange with updated hashId to mobile app1 and app2 after adding subscription
-- 3) send OnButtonEventNotification to mobile app1 and app2
-- Expected: 
-- 1) Notification with AppID - HMI send notification to App with "FULL" and "LIMITED" HMI Levels
-- 2) Notification without AppID - HMI send notification only App with "FULL" HMI Level.
-- Actual result:
-- 1) HMI send notification only App with "FULL" HMI Level.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application2.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function hmiLeveltoLimited(pAppId)
    common.getHMIConnection(pAppId):SendNotification("BasicCommunication.OnAppDeactivated",
        { appID = common.getHMIAppId(pAppId) })
	common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
	    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function subscribeButton(pAppId)
    local cid = common.getMobileSession(pAppId):SendRPC("SubscribeButton", { buttonName = "OK" })
    EXPECT_HMICALL("Buttons.SubscribeButton",{ appID = common.getHMIAppId(pAppId), buttonName = "OK" })
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        end)
    common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  end

local function OnButtonEventWithoutAppID()
    common.getHMIConnection(1):SendNotification("Buttons.OnButtonEvent",
        { name = "OK", mode = "BUTTONDOWN" })
    common.getHMIConnection(1):SendNotification("Buttons.OnButtonPress",
        { name = "OK", mode = "SHORT" })
    common.getHMIConnection(1):SendNotification("Buttons.OnButtonEvent",
        { name = "OK", mode = "BUTTONUP" })

    common.getMobileSession(1):ExpectNotification( "OnButtonEvent",
        { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
        { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
        :Times(2)
     common.getMobileSession(1):ExpectNotification( "OnButtonPress",
        { buttonName = pButtonName, buttonPressMode = "SHORT"})    

    common.getMobileSession(2):ExpectNotification( "OnButtonEvent",
        { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
        { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
        :Times(0)
    common.getMobileSession(2):ExpectNotification( "OnButtonPress",
        { buttonName = pButtonName, buttonPressMode = "SHORT"})
        :Times(0)    
end

local function OnButtonEventWithAppID()
    common.getHMIConnection(1):SendNotification("Buttons.OnButtonEvent",
        { name = "OK", mode = "BUTTONDOWN", appID = common.getHMIAppId(1) })
    common.getHMIConnection(1):SendNotification("Buttons.OnButtonPress",
        { name = "OK", mode = "SHORT", appID = common.getHMIAppId(1) })
    common.getHMIConnection(1):SendNotification("Buttons.OnButtonEvent",
        { name = "OK", mode = "BUTTONUP", appID = common.getHMIAppId(1) })

    common.getHMIConnection(2):SendNotification("Buttons.OnButtonEvent",
        { name = "OK", mode = "BUTTONDOWN", appID = common.getHMIAppId(2) })
    common.getHMIConnection(2):SendNotification("Buttons.OnButtonPress",
        { name = "OK", mode = "SHORT", appID = common.getHMIAppId(2) })
    common.getHMIConnection(2):SendNotification("Buttons.OnButtonEvent",
        { name = "OK", mode = "BUTTONUP", appID = common.getHMIAppId(2) })

    common.getMobileSession(1):ExpectNotification( "OnButtonEvent",
        { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
        { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
        :Times(2)
     common.getMobileSession(1):ExpectNotification( "OnButtonPress",
        { buttonName = pButtonName, buttonPressMode = "SHORT"})    

    common.getMobileSession(2):ExpectNotification( "OnButtonEvent",
        { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
        { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
        :Times(2)
    common.getMobileSession(2):ExpectNotification( "OnButtonPress",
        { buttonName = pButtonName, buttonPressMode = "SHORT"})    
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App2", common.activateApp, { 2 })

runner.Step("Subscribe on button OK App1", subscribeButton, { 1 })
runner.Step("Subscribe on button OK App2", subscribeButton, { 2 })

runner.Step("Set App1 HMI Level to Limited)", hmiLeveltoLimited, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })

-- [[ Test ]]
runner.Title("Test")
runner.Step("OnButtonEvent with App ID", OnButtonEventWithAppID)
runner.Step("OnButtonEvent without App ID", OnButtonEventWithoutAppID)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
