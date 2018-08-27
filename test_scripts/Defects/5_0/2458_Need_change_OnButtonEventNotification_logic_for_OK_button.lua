---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2458
--
-- Description:
-- Need change OnButtonEventNotification logic for OK button
-- Precondition:
-- Core and HMI are started.
-- In case:
-- 1) Activate first App with HMI Level - "FULL" and second App with HMI Level "LIMITED".
-- 2) Send On Button Event without App id, ExpectNotification only on App with "FULL" HMI level.
-- 3) Send On Button Event with App id, ExpectNotification on App with "FULL" and "LIMITED" HMI levels. 
-- Actual result:
-- 1) HMI send notification only App with "FULL" HMI Level.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function hmiLeveltoLimited(pAppId)
    common.getHMIConnection(pAppId):SendNotification("BasicCommunication.OnAppDeactivated",
        { appID = common.getHMIAppId(pAppId) })
	common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
	    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function subscribeButton(pAppId)
    local cid = common.getMobileSession(pAppId):SendRPC("SubscribeButton", { buttonName = "OK"})
    common.getHMIConnection(pAppId):ExpectNotification("Buttons.OnButtonSubscription",
        { appID = common.getHMIAppId(pAppId), name = "OK", isSubscribed = true })
    common.getMobileSession(pAppId):ExpectResponse( cid, {success = true, resultCode = "SUCCESS"})
    common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
end

local function OnButtonEventWithoutAppID()
    common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = "OK", mode = "BUTTONUP", appID = common.getHMIAppId(pAppId) })
    common.getMobileSession(1):ExpectNotification( "OnButtonEvent")
    :Times(0)
    common.getMobileSession(2):ExpectNotification( "OnButtonEvent",
        { buttonName = "OK", buttonEventMode = "BUTTONUP"})
end

local function OnButtonEventWithAppID(pParam1, pParam2)
    common.getHMIConnection(pParam1):SendNotification("Buttons.OnButtonEvent",
    { name = "OK", mode = "BUTTONUP", appID = common.getHMIAppId(pParam1) })
    common.getHMIConnection(pParam2):SendNotification("Buttons.OnButtonEvent",
    { name = "OK", mode = "BUTTONUP", appID = common.getHMIAppId(pParam2) })
    common.getMobileSession(pParam1):ExpectNotification( "OnButtonEvent", 
        { buttonName = "OK", buttonEventMode = "BUTTONUP"})
    common.getMobileSession(pParam2):ExpectNotification( "OnButtonEvent", 
        { buttonName = "OK", buttonEventMode = "BUTTONUP"})
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Hmi level LIMITED", hmiLeveltoLimited, { 1 })
runner.Step("SubscribeButton App1", subscribeButton, { 1 })

runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App2(HMI Level FULL)", common.activateApp, { 2 })
runner.Step("SubscribeButton App2", subscribeButton, { 2 })

-- [[ Test ]]
runner.Title("Test")
runner.Step("OnButtonEvent without App ID", OnButtonEventWithoutAppID)
runner.Step("OnButtonEvent with App ID", OnButtonEventWithAppID, { 1, 2 })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
