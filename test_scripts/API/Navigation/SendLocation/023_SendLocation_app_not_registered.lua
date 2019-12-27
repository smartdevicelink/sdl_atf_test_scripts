---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- 1. Request is invalid: Wrong json, parameters of wrong type, string parameters with empty values or whitespace as the
-- only symbol, out of bounds, wrong characters, missing mandatory parameters
-- 2. SDL responds INVALID_DATA, success:false
--
-- Description:
-- SDL receives SendLocation request to not reqistered application
--
-- Steps:
-- SDL receives SendLocation request to not reqistered application
--
-- Expected:
-- SDL responds APPLICATION_NOT_REGISTERED, success:false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')
local mobileSession = require('mobile_session')

--[[ Local Functions ]]
local function sendLocation(self)
	local requestParams = {
	    longitudeDegrees = 1.1,
	    latitudeDegrees = 1.1
	}

    local cid = self.mobileSession2:SendRPC("SendLocation", requestParams)

    EXPECT_HMICALL("Navigation.SendLocation")
    :Times(0)

    self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
    commonSendLocation.delayedExp()
end

local function CreationNewSession(self)
	self.mobileSession2 = mobileSession.MobileSession(
		self,
		self.mobileConnection,
		config.application2.registerAppInterfaceParams
	)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", commonSendLocation.start)
runner.Step("Start session", CreationNewSession)

runner.Title("Test")
runner.Step("SendLocation_APPLICATION_NOT_REGISTERED", sendLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
