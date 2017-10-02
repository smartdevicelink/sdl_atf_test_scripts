---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid and allowed by Policies UnsubscribeWayPoints_request to SDL
--
-- SDL must:
-- 1) transfer UnsubscribeWayPoints_request_ to HMI
-- 2) respond with <resultCode> received from HMI to mobile app

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local successResultCodes = {
  "SUCCESS",
}

local failureResultCodes = {
  "INVALID_DATA",
  "GENERIC_ERROR",
  "REJECTED",
  "UNSUPPORTED_RESOURCE",
  "IGNORED",
  "DISALLOWED"
}

local unexpectedResultCodes = {
  "TIMED_OUT",
  "IN_USE",
  "UNSUPPORTED_REQUEST",
  "ABORTED",
  "RETRY",
  "VEHICLE_DATA_NOT_AVAILABLE",
  "CHAR_LIMIT_EXCEEDED",
  "INVALID_ID",
  "DUPLICATE_NAME",
  "APPLICATION_NOT_REGISTERED",
  "WRONG_LANGUAGE",
  "OUT_OF_MEMORY",
  "TOO_MANY_PENDING_REQUESTS",
  "TOO_MANY_APPLICATIONS",
  "APPLICATION_REGISTERED_ALREADY",
  "WARNINGS",
  "USER_DISALLOWED",
  "TRUNCATED_DATA",
  "UNSUPPORTED_VERSION",
  "VEHICLE_DATA_NOT_ALLOWED",
  "FILE_NOT_FOUND",
  "CANCEL_ROUTE",
  "SAVED",
  "INVALID_CERT",
  "EXPIRED_CERT",
  "RESUME_FAILED",
  "DATA_NOT_AVAILABLE",
  "READ_ONLY"
}

local isSubscribed = false

--[[ Local Functions ]]
local function subscribeWayPoints(self)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  local ret = EXPECT_EVENT(event, "Precondition event")
  if not isSubscribed then
    local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :Do(function(_, data)
        if data.payload.success then isSubscribed = true end
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

local function unsubscribeWayPointsSuccess(pResultCode, self)
  subscribeWayPoints(self)
  :Do(function()
      local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
      EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id, data.method, pResultCode, {})
        end)
      self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = pResultCode })
      :Do(function(_, data)
          if data.payload.success then isSubscribed = false end
        end)
    end)
end

local function unsubscribeWayPointsUnsuccess(pResultCode, isUnsupported, self)
  subscribeWayPoints(self)
  :Do(function()
      local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
      EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
      :Do(function(_, data)
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
          if data.payload.success then isSubscribed = false end
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

runner.Title("Successful codes")
for _, code in pairs(successResultCodes) do
  runner.Step("UnsubscribeWayPoints with " .. code .. " resultCode", unsubscribeWayPointsSuccess, { code })
end

runner.Title("Erroneous codes")
for _, code in pairs(failureResultCodes) do
  runner.Step("UnsubscribeWayPoints with " .. code .. " resultCode", unsubscribeWayPointsUnsuccess, { code, false })
end

runner.Title("Unexpected codes")
for _, code in pairs(unexpectedResultCodes) do
  runner.Step("UnsubscribeWayPoints with " .. code .. " resultCode", unsubscribeWayPointsUnsuccess, { code, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
