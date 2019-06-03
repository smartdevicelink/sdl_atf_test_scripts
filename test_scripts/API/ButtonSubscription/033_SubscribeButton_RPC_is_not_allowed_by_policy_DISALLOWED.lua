---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) SubscribeButton RPC is not allowed by policy
-- 2) Mobile app requests SubscribeButton
-- SDL does:
-- 1) Respond SubscribeButton(DISALLOWED) to mobile app
-- 2) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local errorCode = "DISALLOWED"
local buttonName = "PRESET_0"

--[[ Local Functions ]]
local function pTUpdateFunc(pTbl)
    pTbl.policy_table.functional_groupings["Base-4"].rpcs.SubscribeButton = nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("SubscribeButton on " .. buttonName .. " button, disallowed",
    common.rpcUnsuccess, { 1, "SubscribeButton", buttonName, errorCode })
runner.Step("Button ".. buttonName .. " wasn't Subscribed", common.buttonPressUnsuccess, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
