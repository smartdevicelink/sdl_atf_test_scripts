---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SetMediaClockTimer
-- Item: Happy path
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
-- appID requests SetMediaClockTimer with valid parameters

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
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local updateMode = { "COUNTUP", "COUNTDOWN", "PAUSE", "RESUME", "CLEAR" }

local indicator = { "PLAY_PAUSE", "PLAY", "PAUSE", "STOP" }

local requestParams = {
  startTime = {
    hours = 0,
    minutes = 1,
    seconds = 33
  },
  endTime = {
    hours = 0,
    minutes = 1 ,
    seconds = 35
  }
}

--[[ Local Functions ]]
local function SetMediaClockTimer(pParams, pMode, pIndicator)
  local params = common.cloneTable(pParams)
  params.updateMode = pMode
  params.audioStreamingIndicator = pIndicator
  if pMode == "COUNTDOWN" then
    params.endTime.minutes = params.startTime.minutes - 1
  end
  local cid = common.getMobileSession():SendRPC("SetMediaClockTimer", params)
  common.getHMIConnection():ExpectRequest("UI.SetMediaClockTimer")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, value in pairs (updateMode) do
  for _, value2 in pairs (indicator) do
    runner.Step("SetMediaClockTimer Non Media Positive Case with udate mode " .. value
      .. " " .. value2, SetMediaClockTimer, { requestParams,value,value2 })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
