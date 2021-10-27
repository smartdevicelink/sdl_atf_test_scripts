------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check data resumption is failed in case HMI doesn't respond during default timeout
--  to SubscribeButton request after unexpected disconnect
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is subscribed for <button>
-- 2. Unexpected disconnect and connect are performed
-- 3. App registers with actual hashId
-- 4. SDL sends SubscribeButton(<button>, appId) to HMI during resumption
-- 5. HMI does not response to SubscribeButton(<button>, appId) during default timeout
-- SDL does:
-- - respond RAI(RESUME_FAILED) to mobile app after default timeout is expired
-- In case:
-- 6. HMI sends OnButtonEvent and OnButtonPress notifications <button> to SDL
-- SDL does:
-- - not resend notifications to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PRESET_0"

--[[ Local Functions ]]
local function checkResumptionData(pAppId)
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
    { appID = common.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" },
    { appID = common.getHMIAppId(pAppId), buttonName = buttonName })
  :Times(2)
  :Do(function(_, data)
    if data.params.buttonName ~= buttonName then
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end
  end)
  common.getHMIConnection():ExpectRequest("Buttons.UnsubscribeButton")
  :Times(0)
  :Timeout(12000)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)
common.runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })
common.runner.Step("Unexpected disconnect", common.unexpectedDisconnect)

common.runner.Title("Test")
common.runner.Step("Connect mobile", common.connectMobile)
common.runner.Step("Reregister App, resumption failed",
  common.reRegisterApp, { appSessionId1, checkResumptionData, 12000 })
common.runner.Step("Subscription on ".. buttonName .. " button wasn't Resumed", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected })
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press", common.buttonPress,
  { appSessionId1, "CUSTOM_BUTTON", common.isExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
