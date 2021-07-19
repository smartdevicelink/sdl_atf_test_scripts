------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check processing SubscribeButton RPC with 'CUSTOM_BUTTON' parameter if HMI doesn't respond
--  during default timeout
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app starts registration
-- 2. HMI does not send Buttons.SubscribeButton response during default timeout
-- 3. HMI sends OnButtonEvent and OnButtonPress notification to App
-- SDL does:
-- - not resend notifications to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"
local errorCode = "GENERIC_ERROR"

--[[ Local Functions ]]
local function registerAppSubCustomButton(pAppId, pExpTimesApp)
  if not pAppId then pAppId = 1 end
  if not pExpTimesApp then pExpTimesApp = common.isExpected end
  common.registerAppWOPTU(pAppId)
  common.getHMIConnection(pAppId):ExpectRequest("Buttons.SubscribeButton",
    { appID = common.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" })
  :Do(function()
      -- HMI does not respond
    end)
  :Times(pExpTimesApp)
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration, HMI does not respond on Subscription CUSTOM_BUTTON", registerAppSubCustomButton)
common.runner.Step("Activate app", common.activateApp)
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)

common.runner.Title("Test")
common.runner.Step("On Custom_button press ", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })
common.runner.Step("Failure Subscribe on " ..  buttonName .. " button, return GENERIC_ERROR",
  common.rpcHMIwithoutResponse, { appSessionId1, "SubscribeButton", buttonName, errorCode })
common.runner.Step("On Custom_button press ", common.buttonPress,
  { appSessionId1, buttonName, common.isNotExpected, common.customButtonID })
common.runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("On Custom_button press ", common.buttonPress,
  { appSessionId1, buttonName, common.isExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
