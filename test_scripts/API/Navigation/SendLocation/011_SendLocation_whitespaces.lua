---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Exception 1: empty strings or whitespace as only symbol in string parameter)
--
-- Requirement summary:
-- App requests SendLocation where string parameters are empty or with whitespaces
--
-- Description:
-- App sends SendLocation with invalid payload (invalid json)

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered on SDL

-- Steps:
-- App sends SendLocation where string parameters are empty or with whitespaces

-- Expected:

-- SDL validates parameters of the request
-- SDL responds INVALID_DATA, success: false
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local stringParams = {
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
    locationName ="a",
    locationDescription ="a",
    addressLines = {"hello"},
    phoneNumber ="123456789",
    locationImage =
    {
        value ="icon.png",
    }
}

--[[ Local Functions ]]
local function sendLocation(params, self)
    params["longitudeDegrees"] = 60
    params["latitudeDegrees"] = 60
    params["deliveryMode"] = "PROMPT"
    params["locationImage"]["imageType"] = "DYNAMIC"

    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation"):Times(0)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})

    commonSendLocation.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file", commonSendLocation.putFile, {"icon.png"})

runner.Title("Test - empty strings")
for key,value in pairs(stringParams) do
    local parametersToSend = stringParams
    if (type(value) == "table") then
        for subKey,_ in pairs(value) do
            parametersToSend[key][subKey] = ""
            runner.Step("SendLocation-invalid-type-of-" .. tostring(subKey), sendLocation, {parametersToSend})
        end
    else
        parametersToSend[key] = ""
        runner.Step("SendLocation-invalid-type-of-" .. tostring(key), sendLocation, {parametersToSend})
    end
end

runner.Title("Test - whitespaces")
for key,value in pairs(stringParams) do
    local parametersToSend = stringParams
    if (type(value) == "table") then
        for subKey,_ in pairs(value) do
            parametersToSend[key][subKey] = "   "
            runner.Step("SendLocation-invalid-type-of-" .. tostring(subKey), sendLocation, {parametersToSend})
        end
    else
        parametersToSend[key] = "   "
        runner.Step("SendLocation-invalid-type-of-" .. tostring(key), sendLocation, {parametersToSend})
    end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
