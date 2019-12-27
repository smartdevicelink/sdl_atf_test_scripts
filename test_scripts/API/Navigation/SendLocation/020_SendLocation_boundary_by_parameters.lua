---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- In case mobile application sends valid SendLocation request, SDL must:
-- 1) transfer Navigation.SendLocation to HMI
-- 2) on getting Navigation.SendLocation ("SUCCESS") response from HMI, respond with (resultCode: SUCCESS, success:true)
-- to mobile application.
--
-- Description:
-- App sends SendLocation request with boundary value of parameters.
--
-- Steps:
-- mobile app requests SendLocation with lower and upper bound value of parameters
--
-- Expected:
-- SDL must:
-- 1) transfer Navigation.SendLocation to HMI
-- 2) on getting Navigation.SendLocation ("SUCCESS") response from HMI, respond with (resultCode: SUCCESS, success:true)
-- to mobile application.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Local Variables ]]
local maxAdressLinesArraySize = 4
local string500Char = string.rep("a", 500)
local string255Char = string.rep("a", 255)
local string200Char = string.rep("a", 200)

local maxFileName = string.rep("a", 238)  .. ".png" -- 255 reduced to 242 due to docker limitation

local request_params = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1
}

local addressLinesArrayUpperBoundSize = {}
for i=1,maxAdressLinesArraySize do
    addressLinesArrayUpperBoundSize[i] = "some string"
end
local addressLinesArrayUpperBoundSizeValue = {}
for i=1,maxAdressLinesArraySize do
    addressLinesArrayUpperBoundSizeValue[i] = string500Char
end

local DateTimeParams =
{
    millisecond = {lower = 0, upper = 999},
    second = {lower = 0, upper = 60},
    minute = {lower = 0, upper = 59},
    hour = {lower = 0, upper = 23},
    day = {lower = 1, upper = 31},
    month  = {name = "month", lower = 1, upper = 12},
    --According to comfirmed information before 'should not be any min value specified',
    -- so as min value specified negative value to check correct processing value not from positive range.
    year = {lower = -1, upper = 4095},
    tz_hour = {lower = -12, upper = 14},
    tz_minute = {lower = 0, upper = 59},
}

local addressParams =
{
    "countryName",
    "countryCode",
    "postalCode",
    "administrativeArea",
    "subAdministrativeArea",
    "locality",
    "subLocality",
    "thoroughfare",
    "subThoroughfare",
}

local boundValues ={
    longitudeDegrees = {lower = -180, upper = 180},
    latitudeDegrees = {lower = -90, upper = 90},
    locationName = {lower = "a", upper = string500Char},
    locationDescription = {lower = "a", upper = string500Char},
    phoneNumber = {lower = "a", upper = string500Char},
    addressLines = {lower = {"a"}, upper = {string500Char}}
}

local locationImage = {lower = "a", upper = maxFileName}

local deliveryModeEnum = {
    "PROMPT",
    "DESTINATION",
    "QUEUE"
}

--[[ Local Functions ]]
local function sendLocation(parameter, value, self)
    local parameters  = commonFunctions:cloneTable(request_params)

    parameters[parameter] = value

    local cid = self.mobileSession1:SendRPC("SendLocation", parameters)

    parameters.appID = commonSendLocation.getHMIAppId()

    EXPECT_HMICALL("Navigation.SendLocation", parameters)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end


local function sendLocationAddress(subParam, value, self)
    local parameters  = commonFunctions:cloneTable(request_params)

    parameters["address"] = {}
    parameters.address[subParam] = value

    local cid = self.mobileSession1:SendRPC("SendLocation", parameters)

    parameters.appID = commonSendLocation.getHMIAppId()

    EXPECT_HMICALL("Navigation.SendLocation", parameters)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :ValidIf(function(_,data)
        local ErrorMessage = ""
        local ValidationStatus = true
        for _,k in pairs(addressParams) do
            if data.params.address[k] and not parameters.address[k] then
                ErrorMessage = ErrorMessage .. k .. "\n"
                ValidationStatus = false
            end
        end

        if ValidationStatus == false then
            return false, "SDL sent redundant address parameters to HMI:\n" .. ErrorMessage
        else
            return true
        end
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendLocationImage(value, self)
    local parameters  = commonFunctions:cloneTable(request_params)

    parameters["locationImage"] = {value = value, imageType = "DYNAMIC"}

    local cid = self.mobileSession1:SendRPC("SendLocation", parameters)

    parameters.appID = commonSendLocation.getHMIAppId()
    local deviceID = commonSendLocation.getDeviceMAC()
    parameters.locationImage.value = commonSendLocation.getPathToSDL() .. "storage/"
    .. commonSendLocation.getMobileAppId(1) .. "_" .. deviceID .. "/" ..tostring(value)

    EXPECT_HMICALL("Navigation.SendLocation", parameters)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendLocationTimeStamp(paramVal, boundValue, self)
    local parameters  = commonFunctions:cloneTable(request_params)

    parameters.timeStamp = {}
    parameters.timeStamp[paramVal] = boundValue

    local cid = self.mobileSession1:SendRPC("SendLocation", parameters)

    parameters.appID = commonSendLocation.getHMIAppId()

    if not parameters.timeStamp["tz_hour"] then
        parameters.timeStamp["tz_hour"] = 0
    end
    if not parameters.timeStamp["tz_minute"] then
        parameters.timeStamp["tz_minute"] = 0
    end

    EXPECT_HMICALL("Navigation.SendLocation", parameters)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :ValidIf(function(_,data)
        local ErrorMessage = ""
        local ValidationStatus = true
        for key in pairs(DateTimeParams) do
            if data.params.timeStamp[key] and
             not parameters.timeStamp[key] then
                ErrorMessage = ErrorMessage .. key .. "\n"
                ValidationStatus = false
            end
        end

        if ValidationStatus == false then
            return false, "SDL sent redundant address parameters to HMI:\n" .. ErrorMessage
        else
            return true
        end
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file", commonSendLocation.putFile, {"a"})
runner.Step("Upload file", commonSendLocation.putFile, {maxFileName})

--[[ Test ]]
--[[ Lower bound set]]
runner.Title("Test")
runner.Title("Lower bound value")
for key,value in pairs(boundValues) do
    runner.Step("SendLocation_lower_" .. tostring(key), sendLocation,
        { key, value.lower })
end

runner.Step("SendLocation_lower_locationImage", sendLocationImage,
        { locationImage.lower })

for _, value in pairs(addressParams) do
    runner.Step("SendLocation_lower_address_" .. tostring(value), sendLocationAddress,
        { value, "a" })
end

for key, value in pairs(DateTimeParams) do
    runner.Step("SendLocation_lower_timeStamp_" .. tostring(key), sendLocationTimeStamp,
        { key, value.lower})
end

--[[ Upper bound set]]
runner.Title("Upper bound value")
for key,value in pairs(boundValues) do
    runner.Step("SendLocation_upper_" .. tostring(key), sendLocation,
        { key, value.upper })
end

runner.Step("SendLocation_upper_locationImage", sendLocationImage,
        { locationImage.upper })

for _, value in pairs(addressParams) do
    runner.Step("SendLocation_upper_address_" .. tostring(value), sendLocationAddress,
        { value, string200Char })
end

for key, value in pairs(DateTimeParams) do
    runner.Step("SendLocation_upper_timeStamp_" .. tostring(key), sendLocationTimeStamp,
        { key, value.upper})
end

runner.Step("SendLocation_address_array_max_size", sendLocation,{ "addressLines", addressLinesArrayUpperBoundSize})
runner.Step("SendLocation_address_array_max_size_max_value", sendLocation,
    { "addressLines", addressLinesArrayUpperBoundSizeValue})

for _, value in pairs(deliveryModeEnum) do
    runner.Step("SendLocation_deliveryMode_enum_" .. tostring(value), sendLocation,
        { "deliveryMode", value})
end

--[[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
