---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 1: Exception 2
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid UnsubscribeWayPoints_request to SDL and this request is NOT allowed by Policies
--
-- SDL must:
-- 1) respond "DISALLOWED, success:false" to mobile app

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function unsubscribeWayPoints(self)
  local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
  common:DelayedExp()
end

local function ptuUpdateFunc(pTbl)
  pTbl.policy_table.functional_groupings["WayPoints"].rpcs.UnsubscribeWayPoints = nil
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU, { 1, ptuUpdateFunc })
runner.Step("Activate App", common.activateApp)
runner.Step("SubscribeWayPoints", common.subscribeWayPoints)
runner.Step("Is Subscribed", common.isSubscribed)

runner.Title("Test")
runner.Step("UnsubscribeWayPoints DISALLOWED by policy", unsubscribeWayPoints)
runner.Step("Is still Subscribed", common.isSubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
