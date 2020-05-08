---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. HMI sends OnWayPointChange with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to mobile app for processing
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local notifParams = {
  wayPoints =
  {
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
        value = common.getPathToFileInStorage("missed_icon.png"),
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

--[[ Local Functions ]]
local function subscribeWayPoints()
  local cid = common.getMobileSession():SendRPC("SubscribeWayPoints",{})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  common.getMobileSession():ExpectResponse(cid, {success = true , resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function onWayPointChange()
  common.getHMIConnection():SendNotification("Navigation.OnWayPointChange", notifParams)
  common.getMobileSession():ExpectNotification("OnWayPointChange", notifParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("SubcribleWayPoints", subscribeWayPoints)

runner.Title("Test")
runner.Step("OnWayPointChange with invalid image", onWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
