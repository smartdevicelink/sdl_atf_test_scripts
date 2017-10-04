---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid and allowed by Policies SubscribeWayPoints_request to SDL
--
-- SDL must:
-- 1) transfer SubscribeWayPoints_request_ to HMI
-- 2) respond with <resultCode> received from HMI to mobile app

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local isSubscribed = false
local resultCodes = {
  success = commonNavigation.getSuccessResultCodes("SubscribeWayPoints"),
  failure = commonNavigation.getFailureResultCodes("SubscribeWayPoints"),
  unexpected = commonNavigation.getUnexpectedResultCodes("SubscribeWayPoints"),
  filtered = commonNavigation.getFilteredResultCodes()
}

--[[ Local Functions ]]
local function unsubscribeWayPoints(self)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  local ret = EXPECT_EVENT(event, "Precondition event")
  -- print("isSubscribed: " .. tostring(isSubscribed))
  if isSubscribed then
    local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :Do(function(_, data)
        if data.payload.success then isSubscribed = false end
        RAISE_EVENT(event, event, "Precondition event")
      end)
  else
    local function raise_event()
      RAISE_EVENT(event, event, "Precondition event")
    end
    RUN_AFTER(raise_event, 100)
  end
  return ret
end

local function subscribeWayPointsSuccess(pResultCode, self)
  unsubscribeWayPoints(self)
  :Do(function()
      local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
      EXPECT_HMICALL("Navigation.SubscribeWayPoints")
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id, data.method, pResultCode, {})
        end)
      self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = pResultCode })
      :Do(function(_, data)
          if data.payload.success then isSubscribed = true end
        end)
    end)
end

local function subscribeWayPointsUnsuccess(pResultCode, isUnsupported, self)
  unsubscribeWayPoints(self)
  :Do(function()
      local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
      EXPECT_HMICALL("Navigation.SubscribeWayPoints")
      :Do(function(_,data)
          self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
        end)
      local appResultCode = pResultCode
      if isUnsupported then appResultCode = "GENERIC_ERROR" end
      self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = appResultCode })
      :ValidIf(function(_,data)
          if not data.payload.info then
            return false, "SDL doesn't resend info parameter to mobile App"
          end
          return true
        end)
      :Do(function(_, data)
          if data.payload.success then isSubscribed = true end
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)

runner.Title("Test")
runner.Step("Result Codes", commonNavigation.printResultCodes, { resultCodes })
runner.Title("Successful codes")
for _, code in pairs(resultCodes.success) do
  runner.Step("SubscribeWayPoints with " .. code .. " resultCode", subscribeWayPointsSuccess, { code })
end

runner.Title("Erroneous codes")
for _, code in pairs(resultCodes.failure) do
  runner.Step("SubscribeWayPoints with " .. code .. " resultCode", subscribeWayPointsUnsuccess, { code, false })
end

runner.Title("Unexpected codes")
for _, code in pairs(resultCodes.unexpected) do
  runner.Step("SubscribeWayPoints with " .. code .. " resultCode", subscribeWayPointsUnsuccess, { code, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
