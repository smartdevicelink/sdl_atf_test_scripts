------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check processing of SubscribeButton request with 'PLAY_PAUSE' parameter in case
--  - mobile app is registered with syncMsgVersion (5.0)
--  -'PLAY_PAUSE' is not supported by HMI
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. HMI is not supported PLAY_PAUSE
-- 2. Mobile app is registered with major version=5.0
-- 3. Mobile app requests SubscribeButton(PLAY_PAUSE)
-- SDL does:
-- - not transfer `Buttons.SubscribeButton` request to HMI
-- - respond SubscribeButton(UNSUPPORTED_RESOURCE) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- In case:
-- 4. HMI sends OnButtonEvent and OnButtonPress notifications for "PLAY_PAUSE"
-- SDL does:
-- - not transfer OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5

--[[ Local Variables ]]
local appSessionId1 = 1
local buttonName = "PLAY_PAUSE"
local errorCode = "UNSUPPORTED_RESOURCE"

--[[ Local function ]]
local hmiValues = common.getDefaultHMITable()
for i, buttonNameTab in pairs(hmiValues.Buttons.GetCapabilities.params.capabilities) do
  if (buttonNameTab.name == buttonName) then
    table.remove(hmiValues.Buttons.GetCapabilities.params.capabilities, i)
  end
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiValues })
common.runner.Step("App registration", common.registerAppWOPTU)
common.runner.Step("App activation", common.activateApp)

common.runner.Title("Test")
common.runner.Step("SubscribeButton " .. buttonName .. ", HMI not supported",
  common.rpcUnsuccess, { appSessionId1, "SubscribeButton", buttonName, errorCode })
common.runner.Step("Button ".. buttonName .. " wasn't Subscribed",
  common.buttonPress, { appSessionId1, buttonName, common.isNotExpected })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
