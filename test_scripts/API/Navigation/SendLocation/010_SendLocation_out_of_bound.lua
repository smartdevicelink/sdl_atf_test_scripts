---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Exception 1: out of bounds)
--
-- Requirement summary:
-- App requests SendLocation with some value that is out of bound
--
-- Description:
-- App sends SendLocation with invalid value of parameter

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
local outOfBoundLongitude = {-180.1, 180.1}
local outOfBoundLatitude = {-90.1, 90.1}

local requestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    addressLines =
    {
        "line1",
        "line2",
    },
    address = {
        countryName = "countryName",
        countryCode = "countryName",
        postalCode = "postalCode",
        administrativeArea = "administrativeArea",
        subAdministrativeArea = "subAdministrativeArea",
        locality = "locality",
        subLocality = "subLocality",
        thoroughfare = "thoroughfare",
        subThoroughfare = "subThoroughfare"
    },
    timeStamp = {
        millisecond = 0,
        second = 40,
        minute = 30,
        hour = 14,
        day = 25,
        month = 5,
        year = 2017,
        tz_hour = 5,
        tz_minute = 30
    },
    locationName = "location Name",
    locationDescription = "location Description",
    phoneNumber = "phone Number",
    deliveryMode = "PROMPT"
}

--[[ Local Functions ]]
local function sendLocation(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation", params):Times(0)

    self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "INVALID_DATA"})

    commonSendLocation.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)

runner.Title("Test - out of bound of longitudeDegrees")
for _, value in pairs(outOfBoundLongitude) do
    local paramsToSend = requestParams
    paramsToSend.longitudeDegrees = value
    runner.Step("SendLocation - longitudeDegrees: " .. tostring(value), sendLocation, {paramsToSend})
end

runner.Title("Test - out of bound of latitudeDegrees")
for _, value in pairs(outOfBoundLatitude) do
    local paramsToSend = requestParams
    paramsToSend.latitudeDegrees = value
    runner.Step("SendLocation - latitudeDegrees: " .. tostring(value), sendLocation, {paramsToSend})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
