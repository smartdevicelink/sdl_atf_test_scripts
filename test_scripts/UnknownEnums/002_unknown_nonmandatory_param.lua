---------------------------------------------------------------------------------------------------
-- Description:
-- Mobile sends a non-mandatory param with an unknown enum value. The enum will be filtered out and
-- WARNINGS will be returned because the parameter was not mandatory

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- appID requests SetMediaClockTimer with an unknown audioStreamingIndicator enum

-- Expected:
-- SDL Core filters out the unknown enum. The HMI receives the request without the unknown enum.
-- WARNINGS result is returned to mobile.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  updateMode = "COUNTUP",
  startTime = {
    hours = 0,
    minutes = 0,
    seconds = 0
  },
  audioStreamingIndicator = "UNKNOWN"
}

local hmiRequestParams = {
  updateMode = "COUNTUP",
  startTime = {
    hours = 0,
    minutes = 0,
    seconds = 0
  }
}

local function UnknownMediaClockTimer()
  local CorIdRAI = commonSmoke.getMobileSession():SendRPC("SetMediaClockTimer", requestParams)
  -- Todo: Add info string
  EXPECT_HMICALL("UI.SetMediaClockTimer", hmiRequestParams)
  :Do(function(_,data)
    --hmi side: sending UI.SetMediaClockTimer response
    commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  commonSmoke.getMobileSession():ExpectResponse(CorIdRAI, {
    success = true,
    resultCode = "WARNINGS"
  }):ValidIf(function(_, data)
    return string.match(data.payload.info, "audioStreamingIndicator")
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("Send Mandatory Unknown Enum", UnknownMediaClockTimer)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
