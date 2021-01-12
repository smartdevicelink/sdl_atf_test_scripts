---------------------------------------------------------------------------------------------------
-- User story: API
-- Use case: SetMediaClockTimer
-- Item: Happy path case, forward and back seek indicators
--
-- Requirement summary:
-- [SetMediaClockTimer] SUCCESS: getting SUCCESS:UI.SetMediaClockTimer()
--
-- Description:
-- Mobile application sends SetMediaClockTimer(COUNTDOWN) request with forwardSeekIndicator and backSeekIndicator

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. app1 is registered and activated on SDL
-- c. app1 is currently in Background, Full or Limited HMI level

-- Steps:
-- app1 requests SetMediaClockTimer with COUNTDOWN mode and with valid forwardSeekIndicator and backSeekIndicator values

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if SetMediaClockTimer is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL checks special validation rules for SetMediaClockTimer
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
local indicatorValues = {
    { type = "TRACK" },
    { type = "TIME" },
    { type = "TIME", seekTime = 30 }
}

local requestParams = {
  startTime = {
    hours = 0,
    minutes = 1,
    seconds = 33
  },
  updateMode = "COUNTDOWN",
  audioStreamingIndicator = "STOP"
}

--[[ Local Functions ]]
local function getTestName(forwardIndicator, backIndicator)
    local test_name = "forward_" .. forwardIndicator.type
    if (forwardIndicator.seekTime ~= nil) then
        test_name = test_name .. "_" .. forwardIndicator.seekTime
    end
    test_name = test_name .. "_back_" .. backIndicator.type
    if (backIndicator.seekTime ~= nil) then
        test_name = test_name .. "_" .. backIndicator.seekTime
    end
    return test_name
end

local function sendRPC(pParams, forwardIndicator, backIndicator)
    local params = utils.cloneTable(pParams)
    params.forwardSeekIndicator = forwardIndicator
    params.backSeekIndicator = backIndicator
    
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
for _, v1 in pairs(indicatorValues) do
    for _, v2 in pairs(indicatorValues) do
        runner.Step("SetMediaClockTimer " .. getTestName(v1, v2), sendRPC, { requestParams, v1, v2 })
    end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
