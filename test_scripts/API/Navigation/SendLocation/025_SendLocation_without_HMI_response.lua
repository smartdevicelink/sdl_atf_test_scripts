---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- 1. HMI sends invalid response to SDL
-- 2. SDL responds GENERIC_ERROR, success:false
--
-- Description:
-- SDL responds GENERIC_ERROR, success:false in case of receiving invalid response from HMI
--
-- Steps:
-- App requests SendLocation
-- HMI does not respond to SDL
-- Expected:
-- SDL responds GENERIC_ERROR, success:false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Functions ]]
local function sendLocation(self)
    local params = {
        longitudeDegrees = 1.1,
        latitudeDegrees = 1.1
    }
    local cid = self.mobileSession1:SendRPC("SendLocation", params)
    EXPECT_HMICALL("Navigation.SendLocation")
    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
    :Timeout(11000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU first app", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate first App", commonSendLocation.activateApp)

runner.Title("Test")
runner.Step("SendLocation_without_response_from_HMI", sendLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
