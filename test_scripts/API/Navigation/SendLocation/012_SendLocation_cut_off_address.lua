---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Exception 2)
--
-- Requirement summary:
-- Cut off parameter "address" from request to HMI in case it is empty
--
-- Description:
-- App sends SendLocation with empty address parameter.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered on SDL

-- Steps:
-- appID requests SendLocation with address, longitudeDegrees, latitudeDegrees, deliveryMode and other parameters

-- Expected:

-- SDL validates parameters of the request
-- SDL checks if Navi interface is available on HMI
-- SDL checks if SendLocation is allowed by Policies
-- SDL checks if deliveryMode is allowed by Policies
-- SDL transfers the request without address parameter to HMI
-- SDL receives response from HMI
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local request_params = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    addressLines =
    {
        "line1",
        "line2",
    },
    address = {},
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
local function send_location(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    params.appID = commonSendLocation.getHMIAppId()
    local deviceID = commonSendLocation.getDeviceMAC()
    params.locationImage.value = commonSendLocation.getPathToSDL() .. "storage/"
        .. commonSendLocation.getMobileAppId(1) .. "_" .. deviceID .. "/icon.png"


    EXPECT_HMICALL("Navigation.SendLocation")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :ValidIf(function (_, data)
        if (data.params.address ~= nil) then
            self:FailTestCase("address is present in SDL's request")
        else
            return true
        end
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
runner.Step("Upload file", commonSendLocation.putFile, {"icon.png"})

runner.Title("Test")
runner.Step("SendLocation - all params", send_location, { request_params })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
