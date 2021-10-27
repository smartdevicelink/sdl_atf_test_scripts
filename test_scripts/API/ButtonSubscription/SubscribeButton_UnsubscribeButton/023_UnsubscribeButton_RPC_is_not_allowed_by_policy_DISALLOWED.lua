------------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "DISALLOWED" to UnsubscribeButton request in case
--  'UnsubscribeButton' rpc is not allowed by policy
------------------------------------------------------------------------------------------------------------------------
-- In case:
-- 1. UnsubscribeButton RPC is not allowed by policy
-- 2. Mobile app requests UnsubscribeButton
-- SDL does:
-- - respond UnsubscribeButton(DISALLOWED) to mobile app
-- - not send OnHashChange with updated hashId to mobile app
-- In case:
-- 3. HMI sends OnButtonEvent and OnButtonPress notifications for button
-- SDL does:
-- - transfer OnButtonEvent and OnButtonPress to App
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/ButtonSubscription/commonButtonSubscription')

--[[ Local Variables ]]
local appSessionId1 = 1
local errorCode = "DISALLOWED"
local buttonName = "PRESET_1"

--[[ Local Functions ]]
local function pTUpdateFunc(pTbl)
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.UnsubscribeButton = nil
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("App registration", common.registerApp)
common.runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
common.runner.Step("App activation", common.activateApp)
common.runner.Step("SubscribeButton " .. buttonName, common.rpcSuccess,
  { appSessionId1, "SubscribeButton", buttonName })
common.runner.Step("On Button Press " .. buttonName, common.buttonPress, { appSessionId1, buttonName })

common.runner.Title("Test")
common.runner.Step("UnsubscribeButton on " .. buttonName .. " button, disallowed",
  common.rpcUnsuccess, { appSessionId1, "UnsubscribeButton", buttonName, errorCode })
common.runner.Step("Button  " .. buttonName .. " still subscribed", common.buttonPress, { appSessionId1, buttonName })

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
