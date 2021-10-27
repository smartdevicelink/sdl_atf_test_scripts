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
-- SDL requests the Buttons.SubscribeButton and receives success response from HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion = {
  majorVersion = 4,
  minorVersion = 5,
  patchVersion = 1
}

--[[ Local Functions ]]
local function subscribeButtonSuccess(pButName)
  local cid = commonSmoke.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
  local appIDvalue = commonSmoke.getHMIAppId()
  commonSmoke.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
    { appID = appIDvalue, buttonName = "PLAY_PAUSE" })
  :Do(function(_, data)
      commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  commonSmoke.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  commonSmoke.getMobileSession():ExpectNotification("OnHashChange")
end

local function subscribeButtonInvalidData(pButName)
  local cid = commonSmoke.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
  commonSmoke.getHMIConnection():ExpectRequest("Buttons.SubscribeButton")
  :Times(0)
  commonSmoke.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonSmoke.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")

runner.Step("SubscribeButton " .. "OK" .. " Positive Case", subscribeButtonSuccess, { "OK" })

runner.Step("SubscribeButton " .. "PLAY_PAUSE" .. " Invalid Data Case", subscribeButtonInvalidData, { "PLAY_PAUSE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
