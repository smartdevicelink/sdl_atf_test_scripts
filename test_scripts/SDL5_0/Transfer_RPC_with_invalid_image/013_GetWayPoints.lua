---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests GetWayPoints
-- 2. HMI sends Navigation.GetWayPoints with image that is absent on file system
-- SDL must:
-- 1. transfer the received from HMI response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  wayPointType = "DESTINATION"
}

local responseParams = {
  wayPoints = {
    {
      coordinate =
      {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      },
      locationName = "Hotel",
      addressLines =
      {
        "Hotel Bora",
        "Hotel 5 stars"
      },
      locationDescription = "VIP Hotel",
      phoneNumber = "Phone39300434",
      locationImage =
      {
        value = common.getPathToFileInStorage("missed_icon.png"),
        imageType = "DYNAMIC",
      },
      searchAddress =
      {
        countryName = "countryName",
        countryCode = "countryCode",
        postalCode = "postalCode",
        administrativeArea = "administrativeArea",
        subAdministrativeArea = "subAdministrativeArea",
        locality = "locality",
        subLocality = "subLocality",
        thoroughfare = "thoroughfare",
        subThoroughfare = "subThoroughfare"
      }
    }
  }
}

--[[ Local Functions ]]
local function getWayPoints()
  local cid = common.getMobileSession():SendRPC("GetWayPoints", requestParams)
  requestParams.appID = common.getHMIAppId()
  responseParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", requestParams)
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseParams)
    end)

  local ExpectedResponse = common.cloneTable(responseParams)
  ExpectedResponse.appID = nil
  ExpectedResponse["success"] = true
  ExpectedResponse["resultCode"] = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, ExpectedResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints with invalid image", getWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
