------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check processing of SubscribeButton request with 'OK' parameter in case
--  mobile app is registered with syncMsgVersion (4.5)
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is registered with major version=4.5
-- 2. Mobile app requests SubscribeButton(OK)
-- SDL does:
-- - send Buttons.SubscribeButton(PLAY_PAUSE, appId) to HMI
-- - wait response from HMI
-- - receive Buttons.SubscribeButton(SUCCESS)
-- - respond SubscribeButton(SUCCESS) to mobile app
-- - send OnHashChange with updated hashId to mobile app
-- In case:
-- 3. HMI sends OnButtonEvent and OnButtonPress notifications for "PLAY_PAUSE"
-- SDL does:
-- - transfer OnButtonEvent and OnButtonPress to App for "OK"
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 4
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 5

--[[ Local Variables ]]
local buttonName = "OK"
local buttonExpect = "PLAY_PAUSE"

--[[ Local function ]]
local function rpcSuccess(pButtonName, pButtonExpect)
  local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButtonName })
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
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

common.runner.Title("Test")
common.runner.Step("SubscribeButton " .. buttonName, rpcSuccess, { buttonName, buttonExpect })
common.runner.Step("On Button Press " .. buttonExpect, pressButton_PLAY_PAUSE, { buttonName, buttonExpect })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
