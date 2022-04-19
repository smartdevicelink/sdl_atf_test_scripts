---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
--
-- Requirement summary:
-- 1. Request is sent in NONE, BACKGROUND, FULL, LIMITED levels
-- 2. SDL responds DISALLOWED, success:false to request in NONE level and SUCCESS, success:true in other ones
--
-- Description:
-- App requests UnsubscribeWayPoints in different HMI levels
--
-- Steps:
-- SDL receives UnsubscribeWayPoints request in NONE, BACKGROUND, FULL, LIMITED
--
-- Expected:
-- SDL responds DISALLOWED, success:false in NONE level, SUCCESS, success:true in BACKGROUND, FULL, LIMITED levels
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

--[[ Local Variables ]]
local notification = {
  wayPoints = {
    {
      coordinate = {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      }
    }
  }
}

--[[ Local Functions ]]
local function UnsubscribeWayPointsDisallowed(self)
    local cid = self.mobileSession2:SendRPC("UnsubscribeWayPoints", {})
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
    :Times(0)
    self.mobileSession2:ExpectResponse(cid, {success = false, resultCode = "DISALLOWED"})
    common:DelayedExp()
end

local function UnsubscribeWayPointsSuccess(self)
    local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    self.mobileSession1:ExpectResponse(cid, {success = true , resultCode = "SUCCESS"})
end

local function BringAppToLimitedLevel(self)
    local appIDval = common.getHMIAppId(1)
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
       {appID = appIDval})
    self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED"})
end

local function BringAppToBackgroundLevel(self)
    common.activateApp(2, self)
    self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND"})
end

local function ptuUpdateFunc(pTbl)
    pTbl.policy_table.functional_groupings["WayPoints"].rpcs["UnsubscribeWayPoints"] =
    {hmi_levels = {"BACKGROUND","FULL","LIMITED"}}
    pTbl.policy_table.functional_groupings["WayPoints"].rpcs["OnWayPointChange"] =
    {hmi_levels = {"BACKGROUND","FULL","LIMITED", "NONE"}}
    pTbl.policy_table.functional_groupings["WayPoints"].rpcs["SubscribeWayPoints"] =
    {hmi_levels = {"BACKGROUND","FULL","LIMITED", "NONE"}}
end

local function onWayPointChange(number, self)
    self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
    if number == 1 then
        self.mobileSession1:ExpectNotification("OnWayPointChange", notification)
    else
        self.mobileSession2:ExpectNotification("OnWayPointChange", notification)
        :Times(0)
        common:DelayedExp()
    end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU first app", common.registerAppWithPTU, {1, ptuUpdateFunc})
runner.Step("RAI, PTU second app", common.registerAppWithPTU, {2, ptuUpdateFunc})
runner.Step("Activate first App", common.activateApp, {1})

runner.Title("Test")
runner.Step("UnsubscribeWayPoints_in_NONE", UnsubscribeWayPointsDisallowed)
runner.Step("Prec_SubscribeWayPoints_in_FULL", common.subscribeWayPoints)
runner.Step("UnsubscribeWayPoints_in_FULL", UnsubscribeWayPointsSuccess)
runner.Step("onWayPointChange_after_success_subscription_in_full", onWayPointChange, {0})
runner.Step("Bring_app_to_limited", BringAppToLimitedLevel)
runner.Step("Prec_SubscribeWayPoints_in_LIMITED", common.subscribeWayPoints)
runner.Step("UnsubscribeWayPoints_in_LIMITED", UnsubscribeWayPointsSuccess)
runner.Step("onWayPointChange_after_success_subscription_in_limited", onWayPointChange, {0})
runner.Step("Bring_app_to_background", BringAppToBackgroundLevel)
runner.Step("Prec_SubscribeWayPoints_in_BACKGROUND", common.subscribeWayPoints)
runner.Step("UnsubscribeWayPoints_in_BACKGROUND", UnsubscribeWayPointsSuccess)
runner.Step("onWayPointChange_after_success_subscription_in_background", onWayPointChange, {0})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
