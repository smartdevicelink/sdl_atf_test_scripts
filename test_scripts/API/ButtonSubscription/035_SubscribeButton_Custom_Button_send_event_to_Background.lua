---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app is subscribed for CUSTOM_BUTTON Alert and Default action
-- 2) App is sent to hmi level BACKGROUND
-- 3) Mobile sends OnButtonEvent and OnButtonPress
-- SDL does:
-- 1) Respond OnButtonEvent and OnButtonPress to mobile app for CUSTOM_BUTTON ALERT
-- 2) Not respond OnButtonEvent and OnButtonPress to mobile app for CUSTOM_BUTTON DEFAULT_ACTION
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local buttonName = "CUSTOM_BUTTON"
local customButtonIDAlert = 1
local alertId

local RequestAlert = {
    alertText1 = "alertText1",
    softButtons = {
        {
            type = "BOTH",
            text = "Close",
            image = {
                value = "action.png",
                imageType = "DYNAMIC"
            },
            isHighlighted = true,
            softButtonID = customButtonIDAlert,
            systemAction = "KEEP_CONTEXT"
        }
    }
}

-- [[ Local Functions ]]
local function pTUpdateFunc(pTbl)
    pTbl.policy_table.module_config.notifications_per_minute_by_priority["NONE"] = 2
    pTbl.policy_table.functional_groupings["Base-4"].rpcs["Alert"].hmi_levels = {
        "FULL",
        "BACKGROUND",
        "LIMITED"
    }
end

local function registerSoftButton(pAppId)
    common.getMobileSession(pAppId):SendRPC("Alert", RequestAlert)
    EXPECT_HMICALL("UI.Alert")
    :Do(function(_,data)
        alertId = data.id
    end)
end

local function pressOnButton()
    common.buttonPress (1, buttonName, customButtonIDAlert)
    common.getHMIConnection():SendResponse(alertId, "UI.Alert", "SUCCESS", {})
    common.getMobileSession():ExpectResponse("Alert", { success = true, resultCode = "SUCCESS" })
end

local function app_1_to_BACKGROUND()
    common.activateApp(2)
    common.getMobileSession(1):ExpectNotification("OnHMIStatus",
        { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("App_2 registration", common.registerAppWOPTU, { 2 })
runner.Step("Activate app_1", common.activateApp, { 1 })
runner.Step("Subscribe on Soft button, Alert", registerSoftButton, { 1 })
runner.Step("Press on " .. buttonName .. " Alert", pressOnButton, { buttonName, customButtonIDAlert })
runner.Step("Activate App_2, App_1 goes to BACKGROUND", app_1_to_BACKGROUND)

runner.Title("Test")
runner.Step("Subscribe on Soft button, Alert", registerSoftButton, { 1 })
runner.Step("Press on " .. buttonName .. " Alert",  pressOnButton, { buttonName, customButtonIDAlert })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
