------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check data resumption is failed in case HMI responds with <erroneous> result code
--  to 2nd SubscribeButton request after unexpected disconnect
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for 'button_1' and 'button_2'
-- 2. Unexpected disconnect and connect are performed
-- 3. App registers with actual hashId
-- 4. SDL sends Buttons.SubscribeButton(button_1, appId) to HMI during resumption
-- 5. SDL sends Buttons.SubscribeButton(button_2, appId) to HMI during resumption
-- 6. HMI responds with error code to SubscribeButton(button_1, appId) and success to SubscribeButton(button_2)
-- SDL does:
-- - process error response from HMI and revert subscription for button_2
-- - respond RAI(RESUME_FAILED) to mobile app
-- In case:
-- 7. HMI sends OnButtonEvent and OnButtonPress notifications button_1 to SDL
-- SDL does:
-- - not resend notifications to App
-- In case:
-- 8. HMI sends OnButtonEvent and OnButtonPress notifications button_2 to SDL
-- SDL does:
-- - not resend notifications to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName_1 = "PRESET_0"
local buttonName_2 = "PRESET_1"

--[[ Local Functions ]]
local function checkResumptionData(pAppId)
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
    { appID = common.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" },
    { appID = common.getHMIAppId(pAppId), buttonName = buttonName_1 },
    { appID = common.getHMIAppId(pAppId), buttonName = buttonName_2 })
  :Times(3)
  :Do(function(_, data)
      if data.params.buttonName == buttonName_1 then
        common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
    end)
  common.getHMIConnection():ExpectRequest("Buttons.UnsubscribeButton",
    { appID = common.getHMIAppId(pAppId), buttonName = buttonName_2 })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)
common.runner.Step("SubscribeButton " .. buttonName_1, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName_1 })
common.runner.Step("SubscribeButton " .. buttonName_2, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName_2 })
common.runner.Step("On Button Press " .. buttonName_1, common.buttonPress, { appSessionId1, buttonName_1 })
common.runner.Step("On Button Press " .. buttonName_2, common.buttonPress, { appSessionId1, buttonName_2 })
common.runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.runner.Step("Connect mobile", common.connectMobile)

common.runner.Title("Test")
common.runner.Step("Reregister App, resumption failed",
  common.reRegisterApp, { appSessionId1, checkResumptionData })
common.runner.Step("Subscription on ".. buttonName_1 .. " button wasn't Resumed",
  common.buttonPress, { appSessionId1, buttonName_1, common.isNotExpected })
common.runner.Step("Subscription on ".. buttonName_2 .. " button wasn't Resumed",
  common.buttonPress, { appSessionId1, buttonName_2, common.isNotExpected })
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, "CUSTOM_BUTTON", common.isExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
