---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2460
-- Description: SDL should send SubscribeWayPoints request to HMI during resumption
--
-- Preconditions:
-- 1) App is registered
-- 2) PTU is performed
-- 3) App is activated
-- 2) App is subscribed to WayPoints
--
-- Step:
-- 1) Apps reconnects with actual hashId
-- SDL does:
-- a. perform resumption of data and HMI level after transport reconnect
-- b. transfer SubscribeWayPoints request to HMI during app resumption
-- c. not transfer SubscribeWayPoints response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hashId

--[[ Local Functions ]]
local function ptUpdateForApp(pTbl)
  pTbl.policy_table.functional_groupings.WayPoints.rpcs.OnWayPointChange.hmi_levels = { "FULL", "NONE" }
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "WayPoints" }
end

local function sendSubscribeWaypoints()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints",{})
  common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_,data)
      hashId = data.payload.hashID
    end)
end

local function appResumption()
  common.app.getParams().hashID = hashId
  common.registerAppWOPTU()
  common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
end

local function onWayPointNotif()
  local wayPointParam = {
    locationName = "Location Name",
    coordinate = { latitudeDegrees = 1.1, longitudeDegrees = 1.1 }
  }
  common.getHMIConnection():SendNotification("Navigation.OnWayPointChange", { wayPoints = { wayPointParam }})
  common.getMobileSession():ExpectNotification("OnWayPointChange",{ wayPoints = { wayPointParam }})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { ptUpdateForApp })
runner.Step("App activation", common.activateApp)
runner.Step("SubscribeWayPoints", sendSubscribeWaypoints)
runner.Step("OnWayPointChange", onWayPointNotif)

runner.Title("Test")
runner.Step("Disconnect mobile device", common.mobile.disconnect)
runner.Step("Connect mobile device", common.mobile.connect)
runner.Step("Resumption app", appResumption)
runner.Step("OnWayPointChange after resumption of subscription", onWayPointNotif)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
