---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SubscribeButton
-- Item: Happy path
--
-- Requirement summary:
-- [SubscribeButton] SUCCESS: getting SUCCESS:SubscribeButton()
--
-- Description:
-- Mobile application sends valid SubscribeButton request and gets SubscribeButton "SUCCESS" response from SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests SubscribeButton with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if Buttons interface is available on HMI
-- SDL checks if SubscribeButton is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL sends the Buttons notificaton to HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local buttonName = {
  "OK",
  "PRESET_0",
  "PRESET_1",
  "PRESET_2",
  "PRESET_3",
  "PRESET_4",
  "PRESET_5",
  "PRESET_6",
  "PRESET_7",
  "PRESET_8"
}

local mediaButtonName = {
  "PLAY_PAUSE",
  "SEEKLEFT",
  "SEEKRIGHT",
  "TUNEUP",
  "TUNEDOWN"
}

--[[ Local Functions ]]
local function subscribeButton(pButName)
  local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
  local appIDvalue = common.getHMIAppId()
  common.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription",
    { appID = appIDvalue, name = pButName, isSubscribed = true })
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function subscribeMediaButton(pButName)
  local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
  common.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, v in pairs(buttonName) do
  runner.Step("SubscribeButton " .. v .. " Positive Case", subscribeButton, { v })
end

for _, v in pairs(mediaButtonName) do
  runner.Step("SubscribeButton " .. v .. " Positive Case", subscribeMediaButton, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
