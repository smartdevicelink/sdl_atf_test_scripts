---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: UnsubscribeButton
-- Item: Happy path
--
-- Requirement summary:
-- [UnsubscribeButton] SUCCESS: getting SUCCESS:UnsubscribeButton()
--
-- Description:
-- Mobile application sends valid UnsubscribeButton request and gets UnsubscribeButton "SUCCESS" response from SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests UnsubscribeButton with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if Buttons interface is available on HMI
-- SDL checks if UnsubscribeButton is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL requests the Buttons.UnsubscribeButton and receives success response from HMI
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
  "OK"
}

local mediaButtonName = {
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
local function subscribeButtons(pButName)
  local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
  local appIDvalue = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("Buttons.SubscribeButton", { appID = appIDvalue, buttonName = pButName })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function unsubscribeButton(pButName)
  local cid = common.getMobileSession():SendRPC("UnsubscribeButton", { buttonName = pButName })
  local appIDvalue = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("Buttons.UnsubscribeButton", { appID = appIDvalue, buttonName = pButName })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function unsubscribeMediaButton(pButName)
  local cid = common.getMobileSession():SendRPC("UnsubscribeButton", { buttonName = pButName })
  common.getHMIConnection():ExpectRequest("Buttons.UnsubscribeButton")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "IGNORED" })
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
for _, v in pairs(buttonName) do
  runner.Step("SubscribeButton " .. v .. " Positive Case", subscribeButtons, { v })
end

runner.Title("Test")
for _, v in pairs(buttonName) do
  runner.Step("UnsubscribeButton " .. v .. " Positive Case", unsubscribeButton, { v })
end

for _, v in pairs(mediaButtonName) do
  runner.Step("UnsubscribeButton " .. v .. " Positive Case", unsubscribeMediaButton, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
