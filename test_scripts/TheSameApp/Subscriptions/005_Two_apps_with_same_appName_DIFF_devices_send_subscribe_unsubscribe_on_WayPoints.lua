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
-- 3) Mobiles №1 and №2 are subscribed on WayPoints
--
-- Steps:
-- 1) HMI sent OnWayPointChange notification
--   Check:
--    SDL sends OnWayPointChange notification to Mobiles №1 and №2
-- 2) Mobile №1 App1 requested Unsubscribe from WayPoints
--   Check:
--    SDL sends Navigation.UnsubscribeWayPoints(appId_1) request to HMI
--    SDL receives Navigation.SubscribeWayPoints("SUCCESS") response from HMI
--    SDL sends UnsubscribeWayPoints(SUCCESS) response to Mobile №1
--    SDL sends OnHashChange with updated hashId to Mobile №1
-- 3) HMI sent OnWayPointChange notification
--   Check:
--    SDL sends OnWayPointChange notification to Mobile №2
--    SDL does NOT send OnWayPointChange to Mobile №1
-- 4) Mobile №2 App2 requested Unsubscribe from WayPoints
--   Check:
--    SDL sends Navigation.UnsubscribeWayPoints(appId_2) request to HMI
--    SDL receives Navigation.SubscribeWayPoints("SUCCESS") response from HMI
--    SDL sends UnsubscribeWayPoints(SUCCESS) response to Mobile №2
--    SDL sends OnHashChange with updated hashId to Mobile №2
-- 5) HMI sent OnWayPointChange notification
--   Check:
--    SDL does NOT send OnWayPointChange to Mobiles №1 and №2
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

local function sendUnsubscribeWayPoints(pAppId, pIsLastApp)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("UnsubscribeWayPoints", {})
  local pTime = 0
  if pIsLastApp then pTime = 1 end

  -- SDL -> HMI should send this request only when last app is unsubscribing
    common.hmi.getConnection():ExpectRequest("Navigation.UnsubscribeWayPoints"):Times(pTime)
    :Do(function(_,data)
         common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS",{})
      end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    mobSession:ExpectNotification("OnHashChange")
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
runner.Step("App1 from Mobile 1 requests SubscribeWayPoints", common.sendSubscribeWayPoints, { 1, true })
runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App2 from Mobile 2 requests SubscribeWayPoints", common.sendSubscribeWayPoints, { 2 })

runner.Title("Test")
runner.Step("HMI sends OnWayPointChange - App 1 and 2 receive", common.sendOnWayPointChange, { 2, 1, 2, pWayPoints })

runner.Step("Activate App 1", common.app.activate, { 1 })
runner.Step("App 1 from Mobile 1 unsubscribes from WayPoints", sendUnsubscribeWayPoints, { 1 })
runner.Step("HMI sends OnWayPointChange - App 1 does NOT receive", common.sendOnWayPointChange, { 2, 1, 1, pWayPoints })

runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App 2 from Mobile 2 unsubscribes from WayPoints",     sendUnsubscribeWayPoints, { 2, true })
runner.Step("HMI sends OnWayPointChange - App 1 and 2 do NOT receive",
    common.sendOnWayPointChange, { 2, 1, 0, pWayPoints })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
