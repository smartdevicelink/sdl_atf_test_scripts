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
-- App sends SendLocation request with only mandatory parameters with int values.
--
-- Steps:
-- mobile app requests SendLocation with mandatory parameters longitudeDegrees, latitudeDegrees with int values
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

--[[ Local Variables ]]
local request_params = {
    longitudeDegrees = 1,
    latitudeDegrees = 1
}

--[[ Local Functions ]]
local function send_location(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    params.appID = commonSendLocation.getHMIAppId()

    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)

--[[ Test ]]
runner.Title("Test")
runner.Step("SendLocation - mandatory only - int values", send_location, { request_params })

--[[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
