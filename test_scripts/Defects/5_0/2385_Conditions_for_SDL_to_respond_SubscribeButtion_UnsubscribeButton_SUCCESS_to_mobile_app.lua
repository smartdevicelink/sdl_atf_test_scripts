---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2385
--
-- Description:
-- Conditions for SDL to respond SubscribeButtion/UnsubscribeButton (SUCCESS) to mobile app
-- Precondition:
--
-- In case:
-- 1) SDL successfully sends OnButtonSubscription to HMI
--    and HMI successfully receives OnButtonSubscription during < DefaultTimeout >
-- Expected result:
-- 1) SDL must respond SubscribeButton/UnsubscribeButton (SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local buttonName = {
    "OK",
    "PLAY_PAUSE",
    "SEEKLEFT",
    "SEEKRIGHT",
    "TUNEUP",
    "TUNEDOWN",
    "PRESET_0",
    "PRESET_1",
    "PRESET_2",
    "PRESET_3",
    "PRESET_4",
    "PRESET_5",
    "PRESET_6",
    "PRESET_7",
    "PRESET_8",
    "PRESET_9"
}

--[[ Local Functions ]]
local function subscribeButton(pButName)
    local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", { appID = common.getHMIAppId(), name = pButName, isSubscribed = true })
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
end

local function unsubscribeButton(pButName)
    local cid = common.getMobileSession():SendRPC("UnsubscribeButton", { buttonName = pButName })
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription",
      { appID = common.getHMIAppId(), name = pButName, isSubscribed = false })
      common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, v in pairs(buttonName) do
    runner.Step("SubscribeButton " .. v .. " Positive Case", subscribeButton, { v })
end

for _, v in pairs(buttonName) do
    runner.Step("UnsubscribeButton " .. v .. " Positive Case", unsubscribeButton, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
