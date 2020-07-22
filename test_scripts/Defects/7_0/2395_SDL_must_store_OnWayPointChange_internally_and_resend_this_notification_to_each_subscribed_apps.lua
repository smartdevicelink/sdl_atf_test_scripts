---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2395
--
-- Description:
-- SDL must store OnWayPointChange internally and re-send this notification to each new subscribed apps
--
-- Steps to reproduce:
-- 1) App_1 is subscribed on wayPonts-related data
-- 2) HMI sends OnWayPointChange to SDL
-- SDL does:
--  a) store WayPoint data received from HMI internally
--  b) resend OnWayPointChange notification to App_1
-- 3) App_2 is registered and activated
-- 4) App_2 subscribes to wayPonts-related data
-- SDL does:
--  a) send successful SubscribeWayPoints response to mobile app
--  b) send OnWayPointChange notification to App_2 right after subscription
-- 5) HMI sends OnWayPointChange with updated values to SDL
-- SDL does:
--  a) send notification to mobile App_1 and App_2
-- 6) App_3 is registered and activated
-- 7) App_3 subscribes to wayPonts-related data
-- SDL does:
--  a) send successful SubscribeWayPoints response to mobile app
--  b) send OnWayPointChange notification to App_3 right after subscription with updated values
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local firstAppId = 1
local secondAppId = 2
local thirdAppId = 3
local notifParams = {
  wayPoints = {
    {
      coordinate = {
        latitudeDegrees = -90,
        longitudeDegrees = -180
      },
      locationName = "Ho Chi Minh",
      addressLines = {"182 Le Dai Hanh"},
      locationDescription = "Toa nha Flemington",
      phoneNumber = "1231414",
      locationImage = {
        value = common.getPathToFileInStorage("icon.png"),
        imageType = "DYNAMIC"
      },
      searchAddress = {
        countryName = "aaa",
        countryCode = "084",
        postalCode = "test",
        administrativeArea = "aa",
        subAdministrativeArea = "a",
        locality = "a",
        subLocality = "a",
        thoroughfare = "a",
        subThoroughfare = "a"
      }
    }
  }
}

local notifParamsUpd = {
  wayPoints = {
    {
      coordinate = {
        latitudeDegrees = -89,
        longitudeDegrees = -179
      },
      locationName = "Ho Chi Minh",
      addressLines = {"182 Le Dai Hanh1"},
      locationDescription = "Toa nha Flemington1",
      phoneNumber = "1231416",
      locationImage = {
        value = common.getPathToFileInStorage("icon.png"),
        imageType = "DYNAMIC"
      },
      searchAddress = {
        countryName = "aaa1",
        countryCode = "0841",
        postalCode = "test1",
        administrativeArea = "aa",
        subAdministrativeArea = "a",
        locality = "a",
        subLocality = "a",
        thoroughfare = "a",
        subThoroughfare = "a"
      }
    }
  }
}

--[[ Local Functions ]]
local function pTUpdateFunc(tbl)
  local WayPoints = {
    rpcs = {
      GetWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      },
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      },
      UnsubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      },
      OnWayPointChange =  {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = WayPoints
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
    { "Base-4", "WayPoints" }
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID] =
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID]
  tbl.policy_table.app_policies[config.application3.registerAppInterfaceParams.fullAppID] =
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID]
end

local function subscribeWayPoints()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints", {})
  common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  common.getMobileSession():ExpectNotification("OnWayPointChange"):Times(0)
end

local function onWayPointChange()
  common.getHMIConnection():SendNotification("Navigation.OnWayPointChange", notifParams)
  common.getMobileSession():ExpectNotification("OnWayPointChange", notifParams)
end

local function onWayPointChange2apps()
  common.getHMIConnection():SendNotification("Navigation.OnWayPointChange", notifParamsUpd)
  common.getMobileSession(1):ExpectNotification("OnWayPointChange", notifParamsUpd)
  common.getMobileSession(2):ExpectNotification("OnWayPointChange", notifParamsUpd)
end

local function subscribeWayPointsAlreadySubscribed()
  local cid = common.getMobileSession(2):SendRPC("SubscribeWayPoints", {})
  common.getMobileSession(2):ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  common.getMobileSession(2):ExpectNotification("OnHashChange")
  common.getMobileSession(2):ExpectNotification("OnWayPointChange", notifParams)
  common.getMobileSession(1):ExpectNotification("OnWayPointChange"):Times(0)
end

local function subscribeWayPointsAlreadySubscribed2apps()
  local cid = common.getMobileSession(3):SendRPC("SubscribeWayPoints", {})
  common.getMobileSession(3):ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  common.getMobileSession(3):ExpectNotification("OnHashChange")
  common.getMobileSession(3):ExpectNotification("OnWayPointChange", notifParamsUpd)
  common.getMobileSession(2):ExpectNotification("OnWayPointChange"):Times(0)
  common.getMobileSession(1):ExpectNotification("OnWayPointChange"):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App_1", common.registerApp, { firstAppId })
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App_1", common.activateApp, { firstAppId })
runner.Step("SubscribeWayPoints App_1", subscribeWayPoints)
runner.Step("onWayPointChange from HMI", onWayPointChange)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Register App_2", common.registerAppWOPTU, { secondAppId })
runner.Step("Activate App_2", common.activateApp, { secondAppId })
runner.Step("SubscribeWayPoints App_2", subscribeWayPointsAlreadySubscribed)
runner.Step("onWayPointChange from HMI", onWayPointChange2apps)
runner.Step("Register App 3", common.registerAppWOPTU, { thirdAppId })
runner.Step("Activate App 3", common.activateApp, { thirdAppId })
runner.Step("SubscribeWayPoints App_3", subscribeWayPointsAlreadySubscribed2apps)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
