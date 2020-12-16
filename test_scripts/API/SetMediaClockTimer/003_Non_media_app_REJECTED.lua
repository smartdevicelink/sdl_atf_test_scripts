---------------------------------------------------------------------------------------------------
-- User story: API
-- Use case: SetMediaClockTimer
-- Item: REJECTED case, non-media app
--
-- Requirement summary:
-- [SetMediaClockTimer] REJECTED: getting SetMediaClockTimer request from non-media app
--
-- Description:
-- Non-media mobile application sends valid SetMediaClockTimer request

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. Non-media app1 is registered and activated on SDL
-- c. app1 is currently in Background, Full or Limited HMI level

-- Steps:
-- app1 requests SetMediaClockTimer with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if SetMediaClockTimer is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL does not transfer the UI part of request with allowed parameters to HMI
-- SDL responds with (resultCode: REJECTED, success:false) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

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
  audioStreamingIndicator = "PAUSE",
  countRate = 1.1
}

--[[ Local Functions ]]
local function sendRPC(pParams)
  local params = common.cloneTable(pParams)
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
runner.Step("SetMediaClockTimer REJECTED", sendRPC, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
