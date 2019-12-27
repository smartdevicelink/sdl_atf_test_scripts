---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- 1. Request is valid, SendLocation RPC is not allowed by policies
-- 2. SDL responds DISALLOWED, success:false to request
--
-- Description:
-- App requests SendLocation in case parameters section is empty in PT
--
-- Steps:
-- SDL receives allowed SendLocation request and parameters section is empty in PT
--
-- Expected:
-- SDL responds DISALLOWED, success:false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')
local json = require("json")

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
local function ptuUpdateFuncDissalowedRPC(tbl)
	local SendLocstionRpcs = tbl.policy_table.functional_groupings["SendLocation"].rpcs
	SendLocstionRpcs["SendLocation"].parameters = json.EMPTY_ARRAY
end

local function sendLocation(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)
    EXPECT_HMICALL("Navigation.SendLocation")
    :Times(0)
    commonSendLocation.delayedExp()
    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU, { "1", ptuUpdateFuncDissalowedRPC })
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file", commonSendLocation.putFile, {"icon.png"})

runner.Title("Test")
runner.Step("SendLocation_parameters_empty_in_policy_table", sendLocation, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
