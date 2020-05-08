---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Two mobile applications with the same appNames and different appIds from different mobiles send
-- SubscribeWayPoints requests and receive OnWayPointChange notifications.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobiles №1 and №2 are connected to SDL
--
-- Steps:
-- 1) Mobile №1 App1 requested Subscribe on WayPoints
--   Check:
--    SDL sends Navigation.SubscribeWayPoints(appId_1) to HMI
--    SDL receives Navigation.SubscribeWayPoints("SUCCESS") response from HMI
--    SDL sends SubscribeWayPoints("SUCCESS") response to Mobile №1
--    SDL sends OnHashChange with updated hashId to Mobile №1
-- 2) HMI sent OnWayPointChange notification
--   Check:
--    SDL sends OnWayPointChange notification to Mobile №1
--    SDL does NOT send OnWayPointChange to Mobile №2
-- 3) Mobile №2 App2 requested Subscribe on WayPoints
--   Check:
--    SDL sends Navigation.SubscribeWayPoints(appId_1) to HMI
--    SDL sends SubscribeWayPoints("SUCCESS") response to Mobile №2
--    SDL sends OnHashChange with updated hashId to Mobile №2
-- 4) HMI sent OnWayPointChange notification
--   Check:
--    SDL sends OnWayPointChange notification to Mobile №1 and to Mobile №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "Test Application", appID = "0001",  fullAppID = "0000001" },
  [2] = { appName = "Test Application", appID = "00022", fullAppID = "00000022" }
}

local wayPointsGroup = {
  rpcs = {
    GetWayPoints         = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} },
    SubscribeWayPoints   = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} },
    UnsubscribeWayPoints = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} },
    OnWayPointChange     = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} }
  }
}

local pWayPoints = { locationName = "Location Name", coordinate = { latitudeDegrees = 1.1, longitudeDegrees = 1.1 }}

--[[ Local Functions ]]
local function modifyWayPointGroupInPT(pt)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.policy_table.functional_groupings["WayPoints"] = wayPointsGroup
  pt.policy_table.app_policies[appParams[1].fullAppID] = common.cloneTable(pt.policy_table.app_policies["default"])
  pt.policy_table.app_policies[appParams[1].fullAppID].groups = {"Base-4", "WayPoints"}
  pt.policy_table.app_policies[appParams[2].fullAppID] = common.cloneTable(pt.policy_table.app_policies["default"])
  pt.policy_table.app_policies[appParams[2].fullAppID].groups = {"Base-4", "WayPoints"}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modifyWayPointGroupInPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Register App2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })
runner.Step("Activate App 1", common.app.activate, { 1 })

runner.Title("Test")
runner.Step("App1 from Mobile 1 requests SubscribeWayPoints",  common.sendSubscribeWayPoints, { 1, true })
runner.Step("HMI sends OnWayPointChange - App 1 receives",       common.sendOnWayPointChange, { 1, 2, 1, pWayPoints })

runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App2 from Mobile 2 requests SubscribeWayPoints",  common.sendSubscribeWayPoints, { 2 })
runner.Step("HMI sends OnWayPointChange - Apps 1 and 2 receive", common.sendOnWayPointChange, { 2, 1, 2, pWayPoints })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
