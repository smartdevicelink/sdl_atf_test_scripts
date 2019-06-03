---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is registered with major version=4.5
-- 2) Mobile app is subscribed for OK
-- 3) Mobile app requests UnsubscribeButton(OK)
-- SDL does:
-- 1) Send Buttons.UnsubscribeButton(PLAY_PAUSE, appId) to HMI
-- 2) Wait response from HMI
-- 3) Receive Buttons.UnsubscribeButton(SUCCESS)
-- 4) Respond UnsubscribeButton(SUCCESS) to mobile app
-- 5) Send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 4
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 5

--[[ Local Variables ]]
local buttonName = "OK"
local buttonExpect = "PLAY_PAUSE"

--[[ Local functions ]]
local function rpcSuccess( pRpc, pButtonName, pButtonExpect)
    local cid = common.getMobileSession():SendRPC(pRpc, { buttonName = pButtonName })
    EXPECT_HMICALL("Buttons." .. pRpc,{ appID = common.getHMIAppId(), buttonName = pButtonExpect })
        :Do(function(_, data)
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
end

local function pressButton_PLAY_PAUSE(pButtonName_OK, pButtonNameOnHMI)
    common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
        { name = pButtonNameOnHMI, mode = "BUTTONDOWN", appID = common.getHMIAppId() })
    common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
        { name = pButtonNameOnHMI, mode = "SHORT", appID = common.getHMIAppId() })
    common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
        { name = pButtonNameOnHMI, mode = "BUTTONUP", appID = common.getHMIAppId() })
    common.getMobileSession():ExpectNotification("OnButtonEvent",
        { buttonName = pButtonName_OK, buttonEventMode = "BUTTONDOWN"},
        { buttonName = pButtonName_OK, buttonEventMode = "BUTTONUP" })
    :Times(2)
    common.getMobileSession():ExpectNotification("OnButtonPress",
        { buttonName = pButtonName_OK, buttonPressMode = "SHORT" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("SubscribeButton " .. buttonName,
    rpcSuccess, { "SubscribeButton", buttonName, buttonExpect })
runner.Step("On Button Press " .. buttonExpect,
    pressButton_PLAY_PAUSE, { buttonName, buttonExpect })

runner.Title("Test")
runner.Step("UnsubscribeButton " .. buttonName,
    rpcSuccess, { "UnsubscribeButton", buttonName, buttonExpect })
runner.Step("Button ".. buttonName .. " Unsubscribed",
    common.buttonPressUnsuccess, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
