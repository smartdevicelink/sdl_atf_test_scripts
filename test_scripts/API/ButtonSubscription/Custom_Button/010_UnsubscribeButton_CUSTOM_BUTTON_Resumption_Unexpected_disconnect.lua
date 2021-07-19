------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends SubscribeButton RPC with 'CUSTOM_BUTTON' parameter during resumption
--  after unexpected disconnect in case App is unsubscribed from 'CUSTOM_BUTTON'
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mobile app is unsubscribed from 'CUSTOM_BUTTON'
-- 2. Unexpected disconnect and connect are performed
-- 3. App registers with actual hashId
-- SDL does:
-- - send one Buttons.SubscribeButton('CUSTOM_BUTTON') request to HMI during resumption
-- - process successful response from HMI
-- - respond RAI(SUCCESS) to mobile app
-- In case:
-- 4. HMI sends OnButtonEvent and OnButtonPress notifications for 'CUSTOM_BUTTON'
-- SDL does:
-- - resend OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "CUSTOM_BUTTON"

--[[ Local Functions ]]
local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
    { appID = common.getHMIAppId(), buttonName = "CUSTOM_BUTTON" })
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
common.runner.Step("UnsubscribeButton " .. buttonName, common.rpcSuccess,
  { appSessionId1, "UnsubscribeButton", buttonName })
common.runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.runner.Step("Connect mobile", common.connectMobile)

common.runner.Title("Test")
common.runner.Step("Reregister App resumption data",
  common.reRegisterAppSuccess, { appSessionId1, checkResumptionData })
common.runner.Step("Subscribe on Soft button", common.registerSoftButton)
common.runner.Step("On Custom_button press ", common.buttonPress,
  { appSessionId1, buttonName, common.isExpected, common.customButtonID })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
