---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
--
-- Description: Retry strategy after failed HMI PTU on proprietary flow

-- In case:
-- 1. timeout_after_x_seconds is set to 4 seconds in preloaded file
-- 2. secondsBetweenRetries is set to { 1, 2 } in preloaded file
-- 3. Mobile app is registered and activated
-- 4. PTU via HMI is started
-- SDL does:
--   a. start timeout_after_x_seconds timeout
-- 5. Timeout expired
-- SDL does:
--   a. start retry strategy
--   b. send SDL.OnStatusUpdate(UPDATE_NEDDED) to HMI
--   c. send OnSystemRequest(Proprietary) to mobile app
--   d. sends SDL.OnStatusUpdate(UPDATING) to HMI
--   i. start timeout_for_first_try = timeout_after_x_seconds + secondsBetweenRetries[1]
-- 6. Timeout expired
-- SDL does:
--   a. send SDL.OnStatusUpdate(UPDATE_NEDDED) to HMI
--   b. send OnSystemRequest(Proprietary) to mobile app
--   c. sends SDL.OnStatusUpdate(UPDATING) to HMI
--   d. start timeout_for_second_try = timeout_for_first_try + secondsBetweenRetries[2]
-- 7. Timeout expired
-- SDL does:
--   a. send SDL.OnStatusUpdate(UPDATE_NEDDED) to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')
local test = require('testbase')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY" } } }

--[[ Local Variables ]]
local secondsBetweenRetries = { 1, 2 } -- in sec
local timeout_after_x_seconds = 4 -- in sec
local retryNotificationTime = {}
local expectedTimeRetry = { -- in msec
  timeout_after_x_seconds*1000,
  (timeout_after_x_seconds + secondsBetweenRetries[1])*1000,
  (timeout_after_x_seconds*#secondsBetweenRetries + secondsBetweenRetries[1] + secondsBetweenRetries[2])*1000
}
local inaccuracy = 500 -- in msec

--[[ Local Functions ]]
local function updatePreloadedTimeout(pTbl)
  pTbl.policy_table.module_config.timeout_after_x_seconds = timeout_after_x_seconds
  pTbl.policy_table.module_config.seconds_between_retries = secondsBetweenRetries
end

function common.registerApp()
  common.register()
  common.hmi():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" })
  :Times(2)
  :Do(function(_, data)
      common.log("SDL->HMI:", "SDL.OnStatusUpdate(" .. data.params.status .. ")")
      if data.params.status == "UPDATING" then table.insert(retryNotificationTime, timestamp()) end
    end)
end

local function retrySequence()
  common.hmi():SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "PROPRIETARY", fileName = "files/ptu.json" })
  local reserveTime = 2000
  local timeout = expectedTimeRetry[1] + expectedTimeRetry[2] + expectedTimeRetry[3] + reserveTime
  common.mobile():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Times(3)
  :Timeout(timeout)

  common.hmi():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" })
  :Times(5)
  :Timeout(timeout)
  :Do(function(_, data)
      common.log("SDL->HMI:", "SDL.OnStatusUpdate(" .. data.params.status .. ")")
      table.insert(retryNotificationTime, timestamp())
  end)
end

local function checkOnStatusUpdateNotificationTimers()
  local actualCheckTime = {}

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
  for _, value in ipairs(checkTimeIterations) do
    table.insert(actualCheckTime, value[2] - value[1])
  end

  for key, retryTime in pairs(actualCheckTime) do
    if retryTime > expectedTimeRetry[key] + inaccuracy or retryTime < expectedTimeRetry[key] - inaccuracy
      then
        test:FailTestCase("Time between messages UPDATING and UPDATE_NEEDED is not equal to expected.\n"
          .. "Expected time is " .. expectedTimeRetry[key] .. ", actual time is " .. retryTime)
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
runner.Step("Retry sequence", retrySequence)
runner.Step("Check OnStatusUpdate Notification Timers", checkOnStatusUpdateNotificationTimers)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
