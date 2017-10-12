---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) HMI needs more time for processing GetWayPoints request and sends OnResetTimeout to SDL
-- SDL must:
-- 1) renew the default timeout for the GetWayPoints


---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

local response = {
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
        value ="icon.png",
        imageType ="DYNAMIC",
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
local function GetWayPoints(pWayPointType, self)
  local params = {
    wayPointType = pWayPointType
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  response.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
    return data.params.appID == common.getHMIAppId()
  end)
  :Do(function(_,data)
      local function SendOnResetTimeout()
        self.hmiConnection:SendNotification("UI.OnResetTimeout", {appID = common.getHMIAppId(), methodName = "Navigation.GetWayPoints"})
      end
      RUN_AFTER(SendOnResetTimeout, 8000)
      local function sendReponse()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
      end
      RUN_AFTER(sendReponse, 15000)
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  :Timeout(16000)
e

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, wayPointType in pairs({ "ALL", "DESTINATION" }) do
  runner.Step("GetWayPoints OnResetTimeout wayPointType " .. wayPointType, GetWayPoints, { wayPointType })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
