---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 1: Alternative flow 2:  Request is not allowed by Policies
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid SubscribeWayPoints_request to SDL and this request is NOT allowed by Policies
--
-- SDL must:
-- 1) SDL responds DISALLOWED, success:false to mobile application and doesn't transfer this request to HMI

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function subscribeWayPoints(self)
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints"):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false , resultCode = "DISALLOWED" })
  common:DelayedExp()
end

local function ptuUpdateFunc(pTbl)
  pTbl.policy_table.functional_groupings["WayPoints"].rpcs.SubscribeWayPoints = nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWithPTU, { common.appId1, ptuUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SubscribeWayPoints DISALLOWED by policy", subscribeWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
