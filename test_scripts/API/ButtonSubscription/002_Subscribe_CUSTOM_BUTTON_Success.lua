---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- Description:
-- In case:
-- 1) Mobile app starts registration
-- SDL does:
-- 1) Send Buttons.SubscribeButton(custom_button, appId) to HMI during registration
-- 2) Wait response from HMI
-- 3) Receive Buttons.SubscribeButton(SUCCESS)
-- 4) Send response SubscribeButton(SUCCESS) to mobile app
-- 5) Not send OnHashChange with updated hashId to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local buttonName = "CUSTOM_BUTTON"
local CustomButtonID = 1

local Request =
    {
        softButtons =
        {
            {
                text = "Button1",
                systemAction = "DEFAULT_ACTION",
                type = "TEXT",
                isHighlighted = false,
                softButtonID = CustomButtonID
            }
        }
    }

--[[ Local function ]]
local function registerApp(pButtonName)
    common.registerAppWOPTU()
    EXPECT_HMICALL("Buttons.SubscribeButton", { common.getHMIAppId(), buttonName = pButtonName })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
    EXPECT_HMICALL("Buttons.OnButtonSubscription")
    :Times(0)
    common.getMobileSession():ExpectNotification("OnHashChange")
    :Times(0)
end

local function registerSoftButton()
    local cid = common.getMobileSession():SendRPC("Show", Request)
    EXPECT_HMICALL("UI.Show")
    :Do(function(_,data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration and check Subscribe on CUSTOM_BUTTON", registerApp, { buttonName })
runner.Step("Activate app", common.activateApp)
runner.Step("Subscribe on Soft button", registerSoftButton)
runner.Step("On Custom_button press ", common.buttonPress, { 1, buttonName, CustomButtonID })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
