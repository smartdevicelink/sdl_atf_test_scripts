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
-- 1) mobile application sends second valid and allowed request during the first one is processing on HMI
-- SDL must:
-- 1) respond "IN_USE, success:false" to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')

local response1 ={}
  response1.wayPoints =
  {{
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
  } }

local response2 = {}

--[[ Local Functions ]]
local function GetWayPoints(self)
  local request1 = { 
    wayPointType = "ALL"
  }
    local request2 = { 
    wayPointType = "DESTINATION"
  }

  response1.appID = commonLastMileNavigation.getHMIAppId()
  response2.appID = commonLastMileNavigation.getHMIAppId()

  local cid = self.mobileSession1:SendRPC("GetWayPoints", request1)

  EXPECT_HMICALL("Navigation.GetWayPoints", request1, request2)
  :Do(function(exp, data)
    if exp.occurences == 1 then        
      local function sendSecondRequest()        
        local cid2 = self.mobileSession1:SendRPC("GetWayPoints", request2)
        self.mobileSession1:ExpectResponse(cid2, { success = false, resultCode = "IN_USE"})
      end
      RUN_AFTER(sendSecondRequest, 1000)
          
      local function sendReponse()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response1) 
      end
      RUN_AFTER(sendReponse, 2000) 
    else
      self.hmiConnection:SendResponse(data.id, data.method, "IN_USE", response2)
    end
  end):Times(2)    
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI, PTU", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate App", commonLastMileNavigation.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints, IN_USE response in case second request from mobile app during first one is processing on HMI ", GetWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
