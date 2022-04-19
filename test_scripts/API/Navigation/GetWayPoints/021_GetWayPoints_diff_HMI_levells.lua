---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
--
-- Requirement summary:
-- 1. Request is sent in NONE, BACKGROUND, FULL, LIMITED levels
-- 2. SDL responds DISALLOWED, success:false to request in NONE level and SUCCESS, success:true in other ones
--
-- Description:
-- App requests GetWayPoints in different HMI levels
--
-- Steps:
-- SDL receives GetWayPoints request in NONE, BACKGROUND, FULL, LIMITED
--
-- Expected:
-- SDL responds DISALLOWED, success:false in NONE level, SUCCESS, success:true in BACKGROUND, FULL, LIMITED levels
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

--[[ Local Variables ]]
local params = {
        wayPointType = "ALL"
      }

--[[ Local Functions ]]
local function GetWayPointsDisallowed(self)
    local cid = self.mobileSession2:SendRPC("GetWayPoints", params)
    EXPECT_HMICALL("Navigation.GetWayPoints")
    :Times(0)
    self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
    common:DelayedExp()
end

local function GetWayPointsSuccess(fParams, self)
    local lParams = commonFunctions:cloneTable(params)
    local cid = self.mobileSession1:SendRPC("GetWayPoints", fParams)
    lParams.appID = common.getHMIAppId()
    local lResponse = { }
    lResponse.wayPoints = {{ locationName = "Hotel" }}
    lResponse.appID = common.getHMIAppId()
    EXPECT_HMICALL("Navigation.GetWayPoints", lParams)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", lResponse)
    end)
    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", wayPoints = lResponse.wayPoints })
end

local function BringAppToLimitedLevel(self)
    local appIDval = common.getHMIAppId(1)
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
       { appID = appIDval })
    self.mobileSession1:ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED" })
end

local function BringAppToBackgroundLevel(self)
    common.activateApp(2, self)
    self.mobileSession1:ExpectNotification("OnHMIStatus",{ hmiLevel = "BACKGROUND" })
end

local function ptuUpdateFunc(pTbl)
    pTbl.policy_table.functional_groupings["WayPoints"].rpcs.GetWayPoints =
    { hmi_levels = {"BACKGROUND","FULL","LIMITED" }}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU first app", common.registerAppWithPTU, {1, ptuUpdateFunc})
runner.Step("RAI, PTU second app", common.registerAppWithPTU, {2, ptuUpdateFunc})
runner.Step("Activate first App", common.activateApp, {1})

runner.Title("Test")
runner.Step("GetWayPoints_in_NONE", GetWayPointsDisallowed)
runner.Step("GetWayPoints_in_FULL", GetWayPointsSuccess, { params })
runner.Step("Bring_app_to_limited", BringAppToLimitedLevel)
runner.Step("GetWayPoints_in_LIMITED", GetWayPointsSuccess, { params })
runner.Step("Bring_app_to_background", BringAppToBackgroundLevel)
runner.Step("GetWayPoints_in_BACKGROUND", GetWayPointsSuccess, { params })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
