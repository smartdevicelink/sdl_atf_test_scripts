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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

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
  "PRESET_8"
}

--[[ Local Functions ]]
local function subscribeButtons(pButName, self)
  local cid = self.mobileSession1:SendRPC("SubscribeButton", { buttonName = pButName })
  local appIDvalue = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("Buttons.SubscribeButton",{ appID = appIDvalue, buttonName = pButName })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHashChange")
end

local function unsubscribeButton(pButName, self)
  local cid = self.mobileSession1:SendRPC("UnsubscribeButton", { buttonName = pButName })
  local appIDvalue = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("Buttons.UnsubscribeButton",{ appID = appIDvalue, buttonName = pButName })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
for _, v in pairs(buttonName) do
  runner.Step("SubscribeButton " .. v .. " Positive Case", subscribeButtons, { v })
end

runner.Title("Test")
for _, v in pairs(buttonName) do
  runner.Step("UnsubscribeButton " .. v .. " Positive Case", unsubscribeButton, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
