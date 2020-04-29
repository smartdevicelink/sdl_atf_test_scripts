---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: Slider
-- Item: Happy path
--
-- Requirement summary:
-- [Slider] SUCCESS: getting SUCCESS:UI.Slider()
--
-- Description:
-- Mobile application sends valid Slider request and gets UI.Slider "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests Slider with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if Slider is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  numTicks = 7,
  position = 1,
  sliderHeader ="sliderHeader",
  timeout = 1000,
  sliderFooter = { "sliderFooter" }
}

--[[ Local Functions ]]
local function slider(pParams)
  local cid = common.getMobileSession():SendRPC("Slider", pParams)
  pParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.Slider", pParams)
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("UI.OnSystemContext",
        { appID = pParams.appID, systemContext = "HMI_OBSCURED" })
      local function sendReponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { sliderPosition = 1 })
        common.getHMIConnection():SendNotification("UI.OnSystemContext",
          { appID = pParams.appID, systemContext = "MAIN" })
      end
      common.runAfter(sendReponse, 1000)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Slider Positive Case", slider, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
