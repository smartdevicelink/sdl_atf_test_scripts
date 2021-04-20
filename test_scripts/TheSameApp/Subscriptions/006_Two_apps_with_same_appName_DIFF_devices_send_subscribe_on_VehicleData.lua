---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Two mobile applications with the same appNames and different appIds from different mobiles send
-- SubscribeVehicleData requests and receive OnVehicleData notifications.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobiles №1 and №2 are connected to SDL
--
-- Steps:
-- 1) Mobile №1 App1 requested Subscribe on VehicleData("gps")
--   Check:
--    SDL send VeicleInfo.SubscribeVehicleData (appId_1, "gps" = true) to HMI
--    SDL receives VeicleInfo.SubscribeVehicleData("SUCCESS") response from HMI
--    SDL sends SubscribeVehicleData("SUCCESS") response to Mobile №1
--    SDL sends OnHashChange with updated hashId to Mobile №1
-- 2) HMI sent OnVehicleData("gps") notification
--   Check:
--    SDL sends OnVehicleData("gps") notification to Mobile №1
--    SDL does NOT send OnVehicleData to Mobile №2
-- 3) Mobile №2 App2 requested Subscribe on VehicleData("speed", "gps")
--   Check:
--    SDL sends VeicleInfo.SubscribeVehicleData (appId_1, "speed" = true) to HMI
--    SDL receives VeicleInfo.SubscribeVehicleData("SUCCESS") response from HMI
--    SDL sends SubscribeVehicleData("SUCCESS") response to Mobile №2
--    SDL sends OnHashChange with updated hashId to Mobile №2
-- 4) HMI sent OnVehicleData("speed") notification
--   Check:
--    SDL sends OnVehicleData("speed") notification to Mobile №2
--    SDL does NOT send OnVehicleData to Mobile №1
-- 5) HMI sent OnVehicleData("speed", "gps") notification
--   Check:
--    SDL sends OnVehicleData("speed") notification to Mobile №1
--    SDL sends OnVehicleData("speed", "gps") notification to Mobile №2
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

local locationGroup = {
  rpcs = {
    GetVehicleData         = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} },
    OnVehicleData          = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} },
    SubscribeVehicleData   = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} },
    UnsubscribeVehicleData = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} }
  }
}

--[[ Local Functions ]]
local function modifyLocationGroupInPT(pt)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.policy_table.functional_groupings["Location-1"] = locationGroup
  pt.policy_table.app_policies[appParams[1].fullAppID] = common.cloneTable(pt.policy_table.app_policies["default"])
  pt.policy_table.app_policies[appParams[1].fullAppID].groups = {"Base-4", "Location-1"}
  pt.policy_table.app_policies[appParams[2].fullAppID] = common.cloneTable(pt.policy_table.app_policies["default"])
  pt.policy_table.app_policies[appParams[2].fullAppID].groups = {"Base-4", "Location-1"}
end

local function subscribeOnSpeed(pAppId, pFirstApp)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SubscribeVehicleData", { speed = true })
  if pFirstApp then
    common.hmi.getConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { speed = true })
    :Do(function(_,data)
        local hmiRespParams = {
          speed = {
            dataType = "VEHICLEDATA_SPEED",
            resultCode = "SUCCESS"
          }
        }
        common.hmi.getConnection():SendResponse( data.id, data.method, "SUCCESS", hmiRespParams )
      end)
  end
    mobSession:ExpectResponse( cid, { success = true, resultCode = "SUCCESS" })
    mobSession:ExpectNotification( "OnHashChange" )
end

local function subscribeOnSpeedAndGPS(pAppId, pFirstApp)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SubscribeVehicleData", { speed = true, gps = true })
  if pFirstApp then
    common.hmi.getConnection():ExpectRequest(
                     "VehicleInfo.SubscribeVehicleData", { gps = true })
    :Do(function(_,data)
        local hmiRespParams = {
          gps = {
            dataType = "VEHICLEDATA_GPS",
            resultCode = "SUCCESS"
          }
        }
        common.hmi.getConnection():SendResponse( data.id, data.method, "SUCCESS", hmiRespParams )
      end)
  end
    mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    mobSession:ExpectNotification("OnHashChange")
end

local function sendOnVehicleData1(pAppId1, pAppId2, pData)
  local mobSession1 = common.mobile.getSession(pAppId1)
  local mobSession2 = common.mobile.getSession(pAppId2)

  if "gps" == pData then
    common.hmi.getConnection():SendNotification("VehicleInfo.OnVehicleData", {gps = {longitudeDegrees =1.1,
                                                                                     latitudeDegrees = 1.1}} )
    mobSession1:ExpectNotification("OnVehicleData",{gps = {longitudeDegrees =1.1, latitudeDegrees = 1.1}})
    mobSession2:ExpectNotification("OnVehicleData",{gps = {longitudeDegrees =1.1, latitudeDegrees = 1.1}}):Times(0)
  elseif "speed" == pData then
    common.hmi.getConnection():SendNotification("VehicleInfo.OnVehicleData",  { speed = 60.5 } )
    mobSession1:ExpectNotification("OnVehicleData", { speed = 60.5 } )
    mobSession2:ExpectNotification("OnVehicleData", { speed = 60.5 } ):Times(0)
  end
end

local function sendOnVehicleData2(pAppId1, pAppId2)
  local mobSession1 = common.mobile.getSession(pAppId1)
  local mobSession2 = common.mobile.getSession(pAppId2)
  common.hmi.getConnection():SendNotification("VehicleInfo.OnVehicleData",
                                                 { speed = 60.5 , gps = {longitudeDegrees =1.1, latitudeDegrees = 1.1}})
  mobSession1:ExpectNotification("OnVehicleData",{ speed = 60.5 })
  mobSession2:ExpectNotification("OnVehicleData",{ speed = 60.5 , gps = {longitudeDegrees =1.1, latitudeDegrees = 1.1}})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modifyLocationGroupInPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Register App2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })
runner.Step("Activate App 1", common.app.activate, { 1 })

runner.Title("Test")
runner.Step("App1 from Mobile 1 requests Subscribe on Speed", subscribeOnSpeed, { 1, true })
runner.Step("HMI sends OnVehicleData - App 1 receives",       sendOnVehicleData1, { 1, 2, 1, "speed" })

runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App2 from Mobile 2 requests Subscribe on Speed and GPS", subscribeOnSpeedAndGPS, { 2, true })
runner.Step("HMI sends OnVehicleData - App 2 receives",       sendOnVehicleData1, { 2, 1, 1, "gps" })
runner.Step("HMI sends OnVehicleData - Apps 1 and 2 receive", sendOnVehicleData2, { 1, 2 })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
