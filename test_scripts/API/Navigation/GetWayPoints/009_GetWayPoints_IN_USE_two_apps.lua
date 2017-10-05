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
-- 1) app2 sends second valid and allowed request during first one request from app1 is processing  on HMI
-- SDL must:
-- 1) process 2nd request successfully
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local atf_logger = require("atf_logger")

--[[ Local Variables ]]
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
local function log(msg)
  print("[" .. atf_logger.formated_time(true) .. "] " .. msg)
end

local function getWayPoints(self)
  local request1 = {
    wayPointType = "ALL"
  }
  local request2 = {
    wayPointType = "DESTINATION"
  }

  log("App1->SDL: 1st request")
  local cid = self.mobileSession1:SendRPC("GetWayPoints", request1)

  EXPECT_HMICALL("Navigation.GetWayPoints", request1, request2)
  :Do(function(exp, data)
      if exp.occurences == 1 then
        log("SDL->HMI: 1st request")
        local function sendSecondRequest()
          log("App2->SDL: 2nd request")
          local cid2 = self.mobileSession2:SendRPC("GetWayPoints", request2)
          self.mobileSession2:ExpectResponse(cid2, { success = true, resultCode = "SUCCESS" })
          :Do(function()
              log("SDL->App2: 2nd response SUCCESS")
            end)
        end
        RUN_AFTER(sendSecondRequest, 1000)

        local function sendReponse()
          log("HMI->SDL: 1st response SUCCESS")
          response.appID = common.getHMIAppId(1)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
        end
        RUN_AFTER(sendReponse, 2000)
      else
        log("SDL->HMI: 2nd request")
        log("HMI->SDL: 2nd response SUCCESS")
        response.appID = common.getHMIAppId(2)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
      end
    end)
  :Times(2)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      log("SDL->App1: 1st response SUCCESS")
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

for i = 1, 2 do
  runner.Step("RAI, PTU " .. i, common.registerAppWithPTU, { i })
  runner.Step("Activate App " .. i, common.activateApp, { i })
end

runner.Title("Test")
runner.Step("GetWayPoints, SUCCESS for 2nd request during the 1st one is processing on HMI", getWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
