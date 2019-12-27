---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Alternative flow 2)
--
-- Requirement summary:
-- App requests SendLocation with address, deliveryMode, other parameters
-- and without longitudeDegrees or latitudeDegrees or without both longitudeDegrees and latitudeDegrees
--
-- Description:
-- App sends SendLocation without longitudeDegrees or latitudeDegrees parameters.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered on SDL

-- Steps:
-- appID requests SendLocation with address, longitudeDegrees, latitudeDegrees, deliveryMode and other parameters

-- Expected:

-- SDL validates parameters of the request
-- SDL respond to the App with resultCode=INVALID_DATA, success=false

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
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
    deliveryMode = "PROMPT",
    locationImage =
    {
        value = "icon.png",
        imageType = "DYNAMIC",
    }
}

--[[ Local Functions ]]
local function sendLocation(params, parametersToCut, self)
    for _,paramToCutOff in pairs(parametersToCut) do
        params[paramToCutOff] = nil
    end
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    params.appID = commonSendLocation.getHMIAppId()
    local deviceID = commonSendLocation.getDeviceMAC()
    params.locationImage.value = commonSendLocation.getPathToSDL() .. "storage/"
        .. commonSendLocation.getMobileAppId(1) .. "_" .. deviceID .. "/icon.png"

    EXPECT_HMICALL("Navigation.SendLocation")
    :Times(0)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
    commonSendLocation.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file", commonSendLocation.putFile, {"icon.png"})

runner.Title("Test")
runner.Step("SendLocation witout mandatory longitudeDegrees", sendLocation, {requestParams, {"longitudeDegrees"}})
runner.Step("SendLocation witout mandatory latitudeDegrees", sendLocation, {requestParams, {"latitudeDegrees"}})
runner.Step("SendLocation witout both mandatory params",
            sendLocation,
            {requestParams, {"longitudeDegrees", "latitudeDegrees"}})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
