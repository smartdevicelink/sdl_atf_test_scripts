------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check processing of UnsubscribeButton request with 'OK' parameter in case
--   mobile app is registered with syncMsgVersion (4.5)
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is registered with major version=4.5
-- 2. Mobile app is subscribed for OK
-- 3. Mobile app requests UnsubscribeButton(OK)
-- SDL does:
-- - send Buttons.UnsubscribeButton(PLAY_PAUSE, appId) to HMI
-- - wait response from HMI
-- - receive Buttons.UnsubscribeButton(SUCCESS)
-- - respond UnsubscribeButton(SUCCESS) to mobile app
-- - send OnHashChange with updated hashId to mobile app
-- In case:
-- 4. HMI sends OnButtonEvent and OnButtonPress notifications for "PLAY_PAUSE"
-- SDL does:
-- - not transfer OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 4
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 5

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "OK"
local buttonExpect = "PLAY_PAUSE"

--[[ Local functions ]]
local function rpcSuccess( pRpc, pButtonName, pButtonExpect)
  local cid = common.getMobileSession():SendRPC(pRpc, { buttonName = pButtonName })
  common.getHMIConnection():ExpectRequest("Buttons." .. pRpc,
    { appID = common.getHMIAppId(), buttonName = pButtonExpect })
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
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)
common.runner.Step("SubscribeButton " .. buttonName, rpcSuccess, { "SubscribeButton", buttonName, buttonExpect })
common.runner.Step("On Button Press " .. buttonExpect, pressButton_PLAY_PAUSE, { buttonName, buttonExpect })

common.runner.Title("Test")
common.runner.Step("UnsubscribeButton " .. buttonName, rpcSuccess, { "UnsubscribeButton", buttonName, buttonExpect })
common.runner.Step("Button ".. buttonName .. " Unsubscribed", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
