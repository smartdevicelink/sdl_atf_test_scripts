---------------------------------------------------------------------------------------------------
-- Description:
-- Mobile sends a mandatory param with an unknown enum value. The enum will be filtered out and
-- INVALID_DATA will be returned because the parameter was mandatory

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- appID requests SetMediaClockTimer with an unknown updateMode enum

-- Expected:
-- SDL Core attempts to filter out the unknown enum. INVALID_DATA is returned because the filtered
-- parameter was mandatory.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  updateMode = "UNKNOWN",
  audioStreamingIndicator = "PLAY"
}

local function UnknownMediaClockTimer()
  local CorIdRAI = commonSmoke.getMobileSession():SendRPC("SetMediaClockTimer", requestParams)
	commonSmoke.getMobileSession():ExpectResponse(CorIdRAI, {
    success = false,
    resultCode = "INVALID_DATA"
  }):ValidIf(function(_, data)
      return string.match(data.payload.info, "updateMode")
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
