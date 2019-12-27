---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (all parameters has boundary values)
--
-- Requirement summary:
-- App requests SendLocation with boundary values of all parameters
--
-- Description:
-- App sends SendLocation with boundary values of params

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered on SDL

-- Steps:
-- App sends SendLocation with invalid payload (invalid json)

-- Expected:

-- SDL validates parameters of the request
-- SDL responds INVALID_DATA, success: false
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local maxFileName = string.rep("a", 238)  .. ".png" -- 255 reduced to 242 due to docker limitation
local lowerBoundRequest = {
    longitudeDegrees = -180.0,
    latitudeDegrees = -90.0,
    address = {
        countryName = "a",
        countryCode = "a",
        postalCode = "a",
        administrativeArea = "a",
        subAdministrativeArea = "s",
        locality = "a",
        subLocality = "s",
        thoroughfare = "s",
        subThoroughfare = "s"
    },
    timeStamp = {
        second = 0,
        minute = 0,
        hour = 0,
        day = 1,
        month = 1,
        year = 0,
        tz_hour = -12,
        tz_minute = 0
    },
    locationName ="a",
    locationDescription ="a",
    addressLines = {"a"},
    phoneNumber ="1",
    deliveryMode = "PROMPT",
    locationImage =
    {
        value ="a",
        imageType ="DYNAMIC",
    }
}

local upperBoundRequest = {
    longitudeDegrees = 180.0,
    latitudeDegrees = 90.0,
    address = {
        countryName = string.rep("a", 200),
        countryCode = string.rep("a", 50),
        postalCode = string.rep("a", 16),
        administrativeArea = string.rep("a", 200),
        subAdministrativeArea = string.rep("a", 200),
        locality = string.rep("a", 200),
        subLocality = string.rep("a", 200),
        thoroughfare = string.rep("a", 200),
        subThoroughfare = string.rep("a", 200)
    },
    timeStamp = {
        second = 60,
        minute = 59,
        hour = 23,
        day = 31,
        month = 12,
        year = 4095,
        tz_hour = 14,
        tz_minute = 59
    },
    locationName =string.rep("a", 500),
    locationDescription = string.rep("a", 500),
    addressLines = {
        string.rep("a", 500),
        string.rep("a", 500),
        string.rep("a", 500),
        string.rep("a", 500)
    },
    phoneNumber =string.rep("a", 500),
    deliveryMode = "PROMPT",
    locationImage =
    {
        value = maxFileName,
        imageType = "DYNAMIC",
    }
}

--[[ Local Functions ]]
local function sendLocation(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    params.appID = commonSendLocation.getHMIAppId()
    local deviceID = commonSendLocation.getDeviceMAC()
    local mobileImageValue = params.locationImage.value
    params.locationImage.value = commonSendLocation.getPathToSDL() .. "storage/"
        .. commonSendLocation.getMobileAppId(1) .. "_" .. deviceID .. "/" .. mobileImageValue


    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :ValidIf (function(_,data)
        if data.payload.info then
            print("SDL sent redundant info parameter to mobile App ")
            return false
        else
            return true
        end
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file with lower bound name", commonSendLocation.putFile, {"a"})
runner.Step("Upload file with upper bound name", commonSendLocation.putFile, {maxFileName})

runner.Title("Test")
runner.Step("SendLocation-lower-bound-of-all-params", sendLocation, {lowerBoundRequest})
runner.Step("SendLocation-upper-bound-of-all-params", sendLocation, {upperBoundRequest})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
