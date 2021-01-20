---------------------------------------------------------------------------------------------------
-- User story: API
-- Use case: SetMediaClockTimer
-- Item: Happy path, custom countRate
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
-- appID requests SetMediaClockTimer with valid parameters including a custom countRate

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if SetMediaClockTimer is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  startTime = {
    hours = 0,
    minutes = 1,
    seconds = 33
  },
  updateMode = "COUNTUP",
  audioStreamingIndicator = "PLAY_PAUSE",
  countRate = 2.0
}

--[[ Local Functions ]]
local function sendRPC(pParams)
  local params = utils.cloneTable(pParams)
  local cid = common.getMobileSession():SendRPC("SetMediaClockTimer", params)
  params.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.SetMediaClockTimer", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetMediaClockTimer Positive Case with custom countRate", sendRPC, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
