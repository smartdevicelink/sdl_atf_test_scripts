---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 1: Exception 2: request is NOT allowed by Policies
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends valid GetWayPoints_request to SDL and this request is NOT allowed by Policies
-- SDL must:
-- 1) SDL responds DISALLOWED, success:false to mobile application and doesn't transfer this request to HMI

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function getWayPoints(self)
  local params = {
    wayPointType = "ALL"
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
  common:DelayedExp()
end

local function ptuUpdateFunc(pTbl)
  pTbl.policy_table.functional_groupings["WayPoints"].rpcs.GetWayPoints = nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWithPTU, { common.appId1, ptuUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints, DISALLOWED by policy", getWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
