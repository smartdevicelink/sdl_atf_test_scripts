---------------------------------------------------------------------------------------------------
-- User story: API
-- Use case: SetMediaClockTimer
-- Item: INVALID_DATA case, missing startTime in COUNTUP mode
--
-- Requirement summary:
-- [SetMediaClockTimer] INVALID_DATA: getting SetMediaClockTimer(COUNTUP) without required startTime parameter
--
-- Description:
-- Mobile application sends SetMediaClockTimer(COUNTUP) request without startTime parameter 

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. app1 is registered and activated on SDL
-- c. app1 is currently in Background, Full or Limited HMI level

-- Steps:
-- app1 requests SetMediaClockTimer with COUNTUP mode and without startTime parameter

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
  endTime = {
    hours = 0,
    minutes = 1,
    seconds = 35
  },
  updateMode = "COUNTUP",
  audioStreamingIndicator = "PAUSE",
  countRate = 0.5
}

--[[ Local Functions ]]
local function sendRPC(pParams)
  local params = common.cloneTable(pParams)
  local cid = common.getMobileSession():SendRPC("SetMediaClockTimer", params)
  common.getHMIConnection():ExpectRequest("UI.SetMediaClockTimer")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetMediaClockTimer INVALID_DATA", sendRPC, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
