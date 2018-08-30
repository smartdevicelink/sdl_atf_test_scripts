---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2478
--
-- Precondition:
-- SDL Core and HMI are started. App is registered, HMI level = FULL
-- Steps:
-- 1) mobile app successfully subscribed on wayPoints-related parameters and received OnWayPointChange notification
-- 2) mobile app sends UnregisterAppInterface to SDL
-- Expected:
-- 1) SDL successfully unregisters the app and sends UnSubscribeWayPoints to HMI and unsubscribes app internally
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Variables ]]
local notification=
{
  wayPoints =
  {
    {
      coordinate={
        latitudeDegrees = -90,
        longitudeDegrees = -180
      },
      locationName="Ho Chi Minh",
      addressLines={"182 Le Dai Hanh"},
      locationDescription="Toa nha Flemington",
      phoneNumber="1231414",
      locationImage={
        value = "icon.png",
        imageType = "DYNAMIC"
      },
      searchAddress={
        countryName="aaa",
        countryCode="084",
        postalCode="test",
        administrativeArea="aa",
        subAdministrativeArea="a",
        locality="a",
        subLocality="a",
        thoroughfare="a",
        subThoroughfare="a"
      }
    }
  }
}

--[[ Local Functions ]]
local function ptuForApp(tbl)
  local AppGroup = {
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
      },
      UnsubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      },
      OnWayPointChange = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  tbl.policy_table.functional_groupings.NewTestCaseGroup = AppGroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
  { "Base-4", "NewTestCaseGroup" }

  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID] = common.DefaultStruct()
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID].groups =
  { "Base-4", "NewTestCaseGroup" }
end

local function subscribeWayPoints(self)
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  self.mobileSession1:ExpectResponse(cid, {success = true , resultCode = "SUCCESS"})
  self.mobileSession1:ExpectNotification("OnHashChange")
end
local function OnWayPointChange_app_subscribed(notifications, self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notifications)
  self.mobileSession1:ExpectNotification("OnWayPointChange", notifications)
end

local function unregisterAppInterface(self)
  local cid = self.mobileSession1:SendRPC("UnregisterAppInterface", {})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = false })
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
end

local function OnWayPointChange_app_unsubscribed(notifications, self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notifications)
  self.mobileSession1:ExpectNotification("OnWayPointChange", notifications):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_ptu, { ptuForApp })
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("SubscribeWayPoints", subscribeWayPoints)
runner.Step("OnWayPointChange_app_subscribed", OnWayPointChange_app_subscribed, {notification})
runner.Step("UnregisterAppInterface", unregisterAppInterface)
runner.Step("OnWayPointChange_app_unsubscribed", OnWayPointChange_app_unsubscribed, {notification})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
