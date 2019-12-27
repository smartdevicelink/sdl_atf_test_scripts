---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Exception 1: invalid json)
--
-- Requirement summary:
-- App requests SendLocation request, but payload is actually corrupted.
--
-- Description:
-- App sends SendLocation with invalid payload (invalid json)

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

--[[ Local Functions ]]
local function sendLocation(self)
    self.mobileSession1.correlationId = self.mobileSession1.correlationId + 1
    local msg = {
        serviceType      = 7,
        frameInfo        = 0,
        rpcType          = 0,
        rpcFunctionId    = 39,
        rpcCorrelationId = self.mobileSession1.correlationId,
        payload          = '{"longitudeDegrees" 1.1, "latitudeDegrees":1.1}' --<<-- Missing ":"
    }
    self.mobileSession1:Send(msg)

    EXPECT_HMICALL("Navigation.SendLocation"):Times(0)

    self.mobileSession1:ExpectResponse(self.mobileSession1.correlationId,
        { success = false, resultCode = "INVALID_DATA"})

    commonSendLocation.delayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)

runner.Title("Test")
runner.Step("SendLocation-invalid-Json", sendLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
