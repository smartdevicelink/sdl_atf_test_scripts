---------------------------------------------------------------------------------------------------
-- User story: API
-- Use case: SetMediaClockTimer
-- Item: INVALID_DATA case, startTime before endTime in COUNTDOWN mode
--
-- Requirement summary:
-- [SetMediaClockTimer] INVALID_DATA: getting SetMediaClockTimer(COUNTDOWN) with startTime earlier than endTime
--
-- Description:
-- Mobile application sends SetMediaClockTimer(COUNTDOWN) request with invalid timer bounds

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. app1 is registered and activated on SDL
-- c. app1 is currently in Background, Full or Limited HMI level

-- Steps:
-- app1 requests SetMediaClockTimer with COUNTDOWN mode and with startTime earlier than endTime

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if SetMediaClockTimer is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL checks special validation rules for SetMediaClockTimer
-- SDL does not transfer the UI part of request with allowed parameters to HMI
-- SDL responds with (resultCode: INVALID_DATA, success:false) to mobile application
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
  updateMode = "COUNTDOWN",
  audioStreamingIndicator = "STOP",
  countRate = 4.0
}

--[[ Local Functions ]]
local function sendRPC(pParams)
  local cid = common.getMobileSession():SendRPC("SetMediaClockTimer", pParams)
  common.getHMIConnection():ExpectRequest("UI.SetMediaClockTimer")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetMediaClockTimer INVALID_DATA", sendRPC, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
