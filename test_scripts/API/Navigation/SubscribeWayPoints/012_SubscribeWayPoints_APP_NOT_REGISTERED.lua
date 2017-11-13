---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) not registered mobile application sent valid and allowed by Policies SubscribeWayPoints_request
--
-- SDL must:
-- 1) respond with APPLICATION_NOT_REGISTERED, success:false to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local mobileSession = require('mobile_session')

--[[ Local Functions ]]
local function subscribeWayPoints(self)
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false , resultCode = "APPLICATION_NOT_REGISTERED" })
  common:DelayedExp()
end

local function CreationNewSession(self)
  self.mobileSession1 = mobileSession.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams
  )
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Start session", CreationNewSession)

runner.Title("Test")
runner.Step("SubscribeWayPoints_APP_NOT_REGISTERED", subscribeWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
