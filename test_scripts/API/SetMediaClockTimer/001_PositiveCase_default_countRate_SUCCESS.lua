---------------------------------------------------------------------------------------------------
-- User story: API
-- Use case: SetMediaClockTimer
-- Item: Happy path, default countRate
--
-- Requirement summary:
-- [SetMediaClockTimer] SUCCESS: getting SUCCESS:UI.SetMediaClockTimer()
--
-- Description:
-- Mobile application sends valid SetMediaClockTimer request and gets UI.SetMediaClockTimer "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests SetMediaClockTimer with valid parameters and without countRate

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if SetMediaClockTimer is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters along with a default countRate of 1.0 to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  startTime = {
    hours = 0,
    minutes = 1,
    seconds = 33
  },
  endTime = {
    hours = 0,
    minutes = 1,
    seconds = 35
  },
  updateMode = "COUNTUP",
  audioStreamingIndicator = "PAUSE"
}

--[[ Local Functions ]]
local function sendRPC(pParams)
  local params = common.cloneTable(pParams)
  local cid = common.getMobileSession():SendRPC("SetMediaClockTimer", params)
  params.appID = common.getHMIAppId()
  params.countRate = 1.0
  common.getHMIConnection():ExpectRequest("UI.SetMediaClockTimer", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetMediaClockTimer Positive Case", sendRPC, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
