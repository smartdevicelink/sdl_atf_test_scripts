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
local common = require('test_scripts/API/Navigation/commonNavigation')
local events = require("events")

--[[ Local Variables ]]
local isSubscribed = false
local resultCodes = {
  success = common.getSuccessResultCodes("UnsubscribeWayPoints"),
  failure = common.getFailureResultCodes("UnsubscribeWayPoints"),
  unexpected = common.getUnexpectedResultCodes("UnsubscribeWayPoints"),
  unmapped = common.getUnmappedResultCodes("UnsubscribeWayPoints")
}

--[[ Local Functions ]]
local function subscribeWayPoints(self)
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
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

local function unsubscribeWayPointsSuccess(pResultCodeMap, self)
  subscribeWayPoints(self)
  :Do(function()
      local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
      EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id, data.method, pResultCodeMap.hmi, {})
        end)
      self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = pResultCodeMap.mobile })
      :Do(function(_, data)
          if data.payload.success then isSubscribed = false end
        end)
    end)
end

local function unsubscribeWayPointsUnsuccess(pResultCodeMap, self)
  subscribeWayPoints(self)
  :Do(function()
      local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
      EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
      :Do(function(_, data)
          self.hmiConnection:SendError(data.id, data.method, pResultCodeMap.hmi, "Error error")
        end)
      self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = pResultCodeMap.mobile })
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

local function unsubscribeWayPointsUnexpected(pResultCodeMap, self)
  subscribeWayPoints(self)
  :Do(function()
    local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})

    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
    :Do(function(_,data)
        if pResultCodeMap.success then
          self.hmiConnection:SendResponse(data.id, data.method, pResultCodeMap.hmi, {})
        else
          self.hmiConnection:SendError(data.id, data.method, pResultCodeMap.hmi, "Error error")
        end
      end)

    self.mobileSession1:ExpectResponse(cid, { success = pResultCodeMap.success, resultCode = pResultCodeMap.mobile })
    :Do(function(_, data)
        if data.payload.success then isSubscribed = false end
      end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Result Codes", common.printResultCodes, { resultCodes })

runner.Title("Successful codes")
for _, item in pairs(resultCodes.success) do
  runner.Step("UnsubscribeWayPoints with " .. item.hmi .. " resultCode", unsubscribeWayPointsSuccess, { item })
end

runner.Title("Erroneous codes")
for _, item in pairs(resultCodes.failure) do
  runner.Step("UnsubscribeWayPoints with " .. item.hmi .. " resultCode", unsubscribeWayPointsUnsuccess, { item })
end

runner.Title("Unexpected codes")
for _, item in pairs(resultCodes.unexpected) do
  runner.Step("UnsubscribeWayPoints with " .. item.hmi .. " resultCode", unsubscribeWayPointsUnexpected, { item })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
