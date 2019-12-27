---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- 1. Request is invalid: Wrong json, parameters of wrong type, string parameters with empty values or whitespace as the
-- only symbol, out of bounds, wrong characters, missing mandatory parameters
-- 2. SDL responds INVALID_DATA, success:false
--
-- Description:
-- App sends SendLocation request with out of bounds values of locationName, locationDescription, addressLines,
-- phoneNumber, locationImage, timeStamp, address, deliveryMode parameters.
--
-- Steps:
-- mobile app requests SendLocation with out of bounds values
--
-- Expected:
-- SDL responds INVALID_DATA, success:false
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Local Variables ]]
local string501char = string.rep ("a", 501)
local string201char = string.rep ("a", 201)
local requestParams = {
        longitudeDegrees = 1.1,
        latitudeDegrees = 1.1
}

local outBoundValuesForStrings = { outLower = "", outUpper = string501char }

local StringParam = {
    "locationName",
    "locationDescription",
    "addressLines",
    "phoneNumber"
}

local addressParams = {
    "countryName",
    "countryCode",
    "postalCode",
    "administrativeArea",
    "subAdministrativeArea",
    "locality",
    "subLocality",
    "thoroughfare",
    "subThoroughfare"
}

local DateTimeParams = {
    millisecond = { name = "millisecond", outLower = -1, outUpper = 1000 },
    second = { name = "second", outLower = -1, outUpper = 61 },
    minute = { name = "minute", outLower = -1, outUpper = 60 },
    hour = { name = "hour", outLower = -1, outUpper = 24 },
    day = { name = "day", outLower = 0, outUpper = 32 },
    month  = { name = "month", outLower = 0, outUpper = 13 },
    year = { name = "year", outUpper = 4096 },
    tz_hour = { name = "tz_hour", outLower = -13, outUpper = 15 },
    tz_minute = { name = "tz_minute", outLower = -1, outUpper = 60 }
}

local emptyArray = {}
local addressLinesArrayOutUpperBound = {}
for i=1, 5 do
    addressLinesArrayOutUpperBound[i] = "a"
end

--[[ Local Functions ]]
local function sendLocation(parameter, paramValue, self)
    local params = commonFunctions:cloneTable(requestParams)
    params[parameter] = paramValue

    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation")
    :Times(0)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
    commonSendLocation.delayedExp()
end

local function sendLocationAddressLines(paramValue, self)
    local params = commonFunctions:cloneTable(requestParams)
    params.addressLines = paramValue

    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation")
    :Times(0)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
    commonSendLocation.delayedExp()
end

local function sendLocationTimeStamp(innerParam, paramValue, self)
    local params = commonFunctions:cloneTable(requestParams)
    params["timeStamp"] = {}
    params.timeStamp[innerParam] = paramValue

    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation")
    :Times(0)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
    commonSendLocation.delayedExp()
end

local function sendLocationAddress(innerParam, paramValue, self)
    local params = commonFunctions:cloneTable(requestParams)
    params["address"] = {}
    params.address[innerParam] = paramValue

    local cid = self.mobileSession1:SendRPC("SendLocation", params)

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

--[[ Test ]]
--[[ Out lower bound test block ]]
--[[ Parameters: locationName, locationDescription, addressLines, phoneNumber ]]
runner.Title("Test")
runner.Title("Out of lower bound values")
for _, ArrayValue in pairs(StringParam) do
    runner.Step("SendLocation_out_lower" .. tostring(ArrayValue), sendLocation,
        { ArrayValue, outBoundValuesForStrings.outLower })
end

--[[ Parameter: addressLines ]]
runner.Step("SendLocation_addressLines_out_lower_array_value", sendLocationAddressLines,
        {{ outBoundValuesForStrings.outLower }})
runner.Step("SendLocation_addressLines_out_lower_array size", sendLocationAddressLines,
        { emptyArray })

--[[ Parameter: timeStamp ]]
for _, ArrayValue in pairs(DateTimeParams) do
    if ArrayValue.name ~= "year" then
        runner.Step("SendLocation_timeStamp_out_lower_" .. tostring(ArrayValue.name), sendLocationTimeStamp,
            { ArrayValue.name, ArrayValue.outLower })
    -- check 'year out of lower bound' is ommited because according to corfimmed information before SDL don't have
    -- lower bound value and don't process any out of lower bound values of year parameter.
    end
end

--[[ Out upper bound test block ]]
--[[ Parameters: locationName, locationDescription, addressLines, phoneNumber ]]
runner.Title("Out of upper bound values")
for _, ArrayValue in pairs(StringParam) do
    runner.Step("SendLocation_out upper" .. tostring(ArrayValue), sendLocation,
        { ArrayValue, outBoundValuesForStrings.outUpper })
end

--[[ Parameter: addressLines ]]
runner.Step("SendLocation_addressLines_out_upper_array_value", sendLocationAddressLines,
        {{ outBoundValuesForStrings.outUpper }})
runner.Step("SendLocation_addressLines_out_upper_array_size", sendLocationAddressLines,
        { addressLinesArrayOutUpperBound })

--[[ Parameter: timeStamp ]]
for _, ArrayValue in pairs(DateTimeParams) do
    runner.Step("SendLocation_timeStamp_out_upper_" .. tostring(ArrayValue.name), sendLocationTimeStamp,
        { ArrayValue.name, ArrayValue.outUpper })
end

--[[ Parameter: address ]]
for _, ArrayValue in pairs(addressParams) do
    runner.Step("SendLocation_address_out_upper_" .. tostring(ArrayValue), sendLocationAddress,
        { ArrayValue, string201char })
end

--[[ Parameter: deliveryMode ]]
runner.Step("SendLocation_deliveryMode_out_bound", sendLocation,
        { "deliveryMode", "DYNAMIC" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
