---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Exception 1: invalid types of parameters values)
--
-- Requirement summary:
-- App requests SendLocation wit one parameter of wrong type, other parameters are valid
--
-- Description:
-- App sends SendLocation with wrong types of parameters

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

runner.Title("Test")
for key,value in pairs(requestParams) do
    local parametersToSend = requestParams
    local function replaceType(val)
        if (type(val) == "string") then
            return 5
        else
            return "5"
        end
    end
    if (type(value) == "table") then
        for subKey,subValue in pairs(value) do
            parametersToSend[key][subKey] = replaceType(subValue)
            runner.Step("SendLocation-invalid-type-of-" .. tostring(key) .. "-" .. tostring(subKey),
                        sendLocation,
                        {parametersToSend})
        end
    else
        parametersToSend[key] = replaceType(value)
        runner.Step("SendLocation-invalid-type-of-" .. tostring(key), sendLocation, {parametersToSend})
    end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
