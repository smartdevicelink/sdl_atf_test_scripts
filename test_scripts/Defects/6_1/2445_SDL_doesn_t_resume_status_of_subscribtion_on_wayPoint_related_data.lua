---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2445
--
-- Description:
-- Check a resumption of subscription on wayPoint-related data
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) App registered and activated.
-- 3) PTU with permissions for wayPoint-related RPCs is performed
--
-- Steps to reproduce:
-- 1) Mobile app requests SubscribeWayPoints
-- 2) Unexpected disconnect is performed and  receive UnSubscribeWayPoints in this way.
-- SDL does:
--  a) send UnsubscribeWayPoints to HMI
-- 3) App registers with actual hashId
-- SDL does:
--  a) register app successfully
--  b) resume HMI level FULL by sending BC.ActivateApp to HMI
--  c) resumes subscription for wayPoints and sends Navi.SubscribeWayPoints to HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local hashId
local notifParams = {
  wayPoints = {{
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
      countryName = "Some country",
      countryCode = "084",
      postalCode = "test",
      administrativeArea = "adm area",
      subAdministrativeArea = "sub adm area",
      locality = "a",
      subLocality = "a",
      thoroughfare = "a",
      subThoroughfare = "a"
    }
  }}
}

-- [[ Local Functions ]]
local function pTUpdateFunc(tbl)
  local OWgroup = {
  rpcs = {
      GetWayPoints = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
      },
      SubscribeWayPoints = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
      },
      UnsubscribeWayPoints = {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
      },
      OnWayPointChange =  {
          hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = OWgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {
    "Base-4", "NewTestCaseGroup" }
end

local function subscribeWayPoints()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints", {})
  common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
end

local function onWayPointChange()
  common.getHMIConnection():SendNotification("Navigation.OnWayPointChange", notifParams)
  common.getMobileSession():ExpectNotification("OnWayPointChange", notifParams)
end

local function registerAppWithResumption()
  local session = common.mobile.createSession()
  session:StartService(7)
  :Do(function()
      common.app.getParams().hashID = hashId
      local corId = session:SendRPC("RegisterAppInterface", common.app.getParams())
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.app.getParams().appName } })
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
            { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
          :Times(2)
        end)
    end)

  common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  common.getHMIConnection():ExpectNotification("Navigation.UnsubscribeWayPoints")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
  common.mobile.disconnect()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)
runner.Step("SubscribeWayPoints", subscribeWayPoints)
runner.Step("OnWayPointChange", onWayPointChange)
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Open mobile connection", common.init.connectMobile)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Register App with resumption", registerAppWithResumption)
runner.Step("OnWayPointChange after re-registration", onWayPointChange)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
