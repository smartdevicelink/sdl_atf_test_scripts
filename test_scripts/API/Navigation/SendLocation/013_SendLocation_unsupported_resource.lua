---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Exception 3)
--
-- Requirement summary:
-- UNSUPPORTED_RESOURCE in case Navi interface is not available on HMI
--
-- Description:
-- App sends SendLocation will valid parameters but actually Navigation interface is unsupported.

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
-- SDL transfers the request with allowed parameters to HMI
-- SDL receives response from HMI
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')
local hmi_values = require('user_modules/hmi_values')

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
        postalCode = "postalCode"
    },
    locationName = "location Name",
    locationDescription = "location Description",
    phoneNumber = "phone Number",
    deliveryMode = "PROMPT"
}

--[[ Local Functions ]]
local function disableNavigationInterface()
    local params = hmi_values.getDefaultHMITable()
    params.Navigation.IsReady.params.available = false
    return params
end

local function sendLocation(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation", params):Times(0)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
    commonSendLocation.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start, {disableNavigationInterface()})
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)

runner.Title("Test")
runner.Step("SendLocation - Navigation is not available/supported", sendLocation, {requestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
