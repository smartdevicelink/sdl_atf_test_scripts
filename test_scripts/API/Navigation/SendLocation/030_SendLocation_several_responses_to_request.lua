---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- SendLocation with address, longitudeDegrees, latitudeDegrees, deliveryMode and other parameters
--
-- Description:
-- App sends SendLocation with all available parameters.
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered on SDL
--
-- Steps:
-- appID requests SendLocation
-- Expected:
-- SDL validates parameters of the request
-- SDL checks if Navi interface is available on HMI
-- SDL checks if SendLocation is allowed by Policies
-- SDL checks if deliveryMode is allowed by Policies
-- SDL transfers the request with allowed parameters to HMI
-- SDL receives responses from HMI, process first received response
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local requestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1
}

--[[ Local Functions ]]
local function sendLocation(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)
    params.appID = commonSendLocation.getHMIAppId()
    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        local function response1()
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
        local function response2()
            self.hmiConnection:SendError(data.id, data.method, "ABORTED", "Error message")
        end
        local function response3()
            self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error message")
        end
        RUN_AFTER(response1, 300)
        RUN_AFTER(response2, 600)
        RUN_AFTER(response3, 900)
    end)
    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    commonSendLocation.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)

runner.Title("Test")
runner.Step("SendLocation_several_response", sendLocation, {requestParams})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
