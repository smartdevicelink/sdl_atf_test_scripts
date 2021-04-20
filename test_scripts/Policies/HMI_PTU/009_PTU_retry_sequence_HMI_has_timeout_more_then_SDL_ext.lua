---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
--
-- Description: Retry strategy after failed HMI PTU on external_proprietary flow

-- In case:
-- 1. timeout_after_x_seconds is set to 4 seconds in preloaded file
-- 2. secondsBetweenRetries is set to { 1, 2 } in preloaded file
-- 3. Mobile app is registered and activated
-- 4. PTU via HMI is started
-- SDL does:
--   a. start timeout_after_x_seconds timeout
-- 5. Timeout expired
-- SDL does:
--   a. send SDL.OnStatusUpdate(UPDATE_NEEDED) to HMI
-- 6. SDL receives OnSystemRequest(Proprietary) from HMI
-- SDL does:
--   a. send PTU status to updating
--   b. start timeout_after_x_seconds timeout
-- 7. All timeouts expired
-- SDL does:
--   a. send SDL.OnStatusUpdate(UPDATE_NEEDED) to HMI
-- 8. SDL receives OnSystemRequest(Proprietary) from HMI in timeout_after_x_seconds after the first notification
-- SDL does:
--   a. send PTU status to updating
--   b. start timeout_after_x_seconds timeout
-- 9. All timeouts expired
-- SDL does:
--   a. send SDL.OnStatusUpdate(UPDATE_NEEDED) to HMI
-- 10. SDL receives OnSystemRequest(Proprietary) from HMI in secondsBetweenRetries[1] after second notification
-- SDL does:
--   a. send PTU status to updating
--   b. start timeout_after_x_seconds timeout
-- 11. All timeouts expired
-- SDL does:
--   a. send SDL.OnStatusUpdate(UPDATE_NEEDED) to HMI
-- 12. SDL receives OnSystemRequest(Proprietary) from HMI in secondsBetweenRetries[2] after third notification
-- Retry strategy is finished, HMI does not sent OnSystemRequest notification any more till next ignition cycle
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')
local test = require('testbase')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local secondsBetweenRetries = { 1, 2 } -- in sec
local timeout_after_x_seconds = 4 -- in sec
local timeToCheckOnSystemNot = {}
local retryNotificationTime = {}
local expectedTime = { -- in msec
  timeout_after_x_seconds*1000,
  (timeout_after_x_seconds + secondsBetweenRetries[1])*1000,
  (timeout_after_x_seconds  + secondsBetweenRetries[2])*1000 }
local expectedTimeRetry = { -- in msec
  (timeout_after_x_seconds + secondsBetweenRetries[1])*1000,
  (timeout_after_x_seconds + secondsBetweenRetries[2])*1000
}
local inaccuracy = 500 -- in msec

--[[ Local Functions ]]
local function updatePreloadedTimeout(pTbl)
  pTbl.policy_table.module_config.timeout_after_x_seconds = timeout_after_x_seconds
  pTbl.policy_table.module_config.seconds_between_retries = secondsBetweenRetries
end

local function unsuccesfullMobileUpdate()
  common.hmi():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" })
  :DoOnce(function()
      common.hmi():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "files/ptu.json" })
    end)
  :Times(2)
  common.mobile():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Do(function()
      table.insert(timeToCheckOnSystemNot, timestamp())
    end)
end

local function startRetrySequece()
  local function sendOnSystemRequest()
    common.hmi():SendNotification("BasicCommunication.OnSystemRequest",
      { requestType = "PROPRIETARY", fileName = "files/ptu.json" })
    common.log("HMI->SDL:", "BC.OnSystemRequest")
  end
  sendOnSystemRequest()
  RUN_AFTER(sendOnSystemRequest, expectedTimeRetry[1])
  RUN_AFTER(sendOnSystemRequest, expectedTimeRetry[2] + expectedTimeRetry[1])
end

local function retrySequence()
  local inaccuracyOneSec = 1000
  -- timeout_after_x_seconds*1000 - convert timeout_after_x_seconds from sec to msec
  local reserveTime = timeout_after_x_seconds*1000 + inaccuracyOneSec
  local timeout = expectedTime[1] + expectedTime[2] + expectedTime[3] + reserveTime
  common.mobile():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Times(3)
  :Timeout(timeout)
  :Do(function()
      table.insert(timeToCheckOnSystemNot, timestamp())
    end)

  common.hmi():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" })
  :Times(7)
  :Timeout(timeout)
  :Do(function(exp, data)
    common.log("SDL->HMI:", "SDL.OnStatusUpdate(" .. data.params.status .. ")")
    if exp.occurences == 1 then
      startRetrySequece()
    elseif data.params.status == "UPDATING" then
      table.insert(retryNotificationTime, timestamp())
    elseif data.params.status == "UPDATE_NEEDED" then
      table.insert(retryNotificationTime, timestamp())
    end
  end)
end

local function checkOnStatusUpdateNotificationTimers()
  local checkTimeIterations = {
    firstIteration = {
      retryNotificationTime[1],
      retryNotificationTime[2]
    },
    secondIteration = {
      retryNotificationTime[3],
      retryNotificationTime[4]
    },
    thirdIteration = {
      retryNotificationTime[5],
      retryNotificationTime[6]
    }
  }
  local actualCheckTime = {}
  for _, value in pairs(checkTimeIterations) do
    table.insert(actualCheckTime, value[2] - value[1])
  end

  for _, retryTime in pairs(actualCheckTime) do
    -- timeout_after_x_seconds*1000 - convert timeout_after_x_seconds from sec to msec
    if retryTime > timeout_after_x_seconds*1000 + inaccuracy or retryTime < timeout_after_x_seconds*1000 - inaccuracy
      then
        test:FailTestCase("Time between messages UPDATING and UPDATE_NEEDED is not equal to timeout_after_x_seconds.\n"
          .. "Expected time is " .. timeout_after_x_seconds*1000 , ", actual time is " .. retryTime)
    end
  end
end

local function checkOnSystemRequestTimers()
  local actualTime = {}
  local i = 1
  while i < #timeToCheckOnSystemNot do
    table.insert(actualTime, timeToCheckOnSystemNot[i + 1] - timeToCheckOnSystemNot[i])
    i = i + 1
  end

  for key, _ in pairs(actualTime) do
    if actualTime[key] > expectedTime[key] + inaccuracy or actualTime[key] < expectedTime[key] - inaccuracy then
      test:FailTestCase("Time between messages is not equal to retry timeouts.\nExpected result: " .. expectedTime[key]
        .. ". Actual Result: " .. actualTime[key])
    end
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update with retry parameters", common.updatePreloaded, { updatePreloadedTimeout })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Unsuccessful PTU via a HMI", common.unsuccessfulPTUviaHMI)
runner.Step("Unsuccessful PTU via a mobile device", unsuccesfullMobileUpdate)
runner.Step("Retry sequence", retrySequence)
runner.Step("Check OnStatusUpdate Notification Timers", checkOnStatusUpdateNotificationTimers)
runner.Step("Check OnSystemRequest Timers", checkOnSystemRequestTimers)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
