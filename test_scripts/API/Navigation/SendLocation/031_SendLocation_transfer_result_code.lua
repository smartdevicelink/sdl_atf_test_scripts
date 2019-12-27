---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Alternative flow 1)
--
-- Requirement summary:
-- SDL transfer HMI's result code to Mobile
--
-- Description:
-- App sends SendLocation will valid parameters, Navi interface is working.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered on SDL

-- Steps:
-- appID requests SendLocation with address, longitudeDegrees, latitudeDegrees, deliveryMode and other parameters

-- Expected:

-- SDL validates parameters of the request
-- SDL checks if Navi interface is available on HMI
-- SDL checks if SendLocation is allowed by Policies
-- SDL checks if deliveryMode is allowed by Policies
-- SDL transfers the request with allowed parameters to HMI
-- SDL receives response from HMI
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local resultCodes = {
  success = common.getSuccessResultCodes("SendLocation"),
  failure = common.getFailureResultCodes("SendLocation"),
  unexpected = common.getUnexpectedResultCodes("SendLocation"),
  unmapped = common.getUnmappedResultCodes("SendLocation")
}

local params = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1
}

--[[ Local Functions ]]
local function sendLocationSuccess(pResultCodeMap, self)
  local cid = self.mobileSession1:SendRPC("SendLocation", params)

  EXPECT_HMICALL("Navigation.SendLocation", params)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, pResultCodeMap.hmi, {})
    end)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = pResultCodeMap.mobile })
end

local function sendLocationUnsuccess(pResultCodeMap, self)
  local cid = self.mobileSession1:SendRPC("SendLocation", params)

  EXPECT_HMICALL("Navigation.SendLocation", params)
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, pResultCodeMap.hmi, "Error error")
    end)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = pResultCodeMap.mobile })
  :ValidIf(function(_,data)
      if not data.payload.info then
        return false, "SDL doesn't resend info parameter to mobile App"
      end
      return true
    end)
end

local function sendLocationUnexpected(pResultCodeMap, self)
  local cid = self.mobileSession1:SendRPC("SendLocation", params)

  EXPECT_HMICALL("Navigation.SendLocation", params)
  :Do(function(_,data)
      if pResultCodeMap.success then
        self.hmiConnection:SendResponse(data.id, data.method, pResultCodeMap.hmi, {})
      else
        self.hmiConnection:SendError(data.id, data.method, pResultCodeMap.hmi, "Error error")
      end
    end)

  self.mobileSession1:ExpectResponse(cid, { success = pResultCodeMap.success, resultCode = pResultCodeMap.mobile })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerApplicationWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Result Codes", common.printResultCodes, { resultCodes })

runner.Title("Successful codes")
for _, item in pairs(resultCodes.success) do
  runner.Step("SendLocation with " .. item.hmi .. " resultCode", sendLocationSuccess, { item })
end

runner.Title("Erroneous codes")
for _, item in pairs(resultCodes.failure) do
  runner.Step("SendLocation with " .. item.hmi .. " resultCode", sendLocationUnsuccess, { item })
end

runner.Title("Unexpected codes")
for _, item in pairs(resultCodes.unexpected) do
  runner.Step("SendLocation with " .. item.hmi .. " resultCode", sendLocationUnexpected, { item })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
