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
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')

local error_codes = { "GENERIC_ERROR", "INVALID_DATA", "OUT_OF_MEMORY", "REJECTED" }


--[[ Local Functions ]]
local function SubscribeWayPointsUnsuccess(pResultCode, self)
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints"):Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
    end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = pResultCode})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI, PTU", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate App", commonLastMileNavigation.activateApp)

runner.Title("Test")
for _, code in pairs(error_codes) do
    runner.Step("SubscribeWayPoints with " .. code .. " resultCode", SubscribeWayPointsUnsuccess, { code })
end
runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
