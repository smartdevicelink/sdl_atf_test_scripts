---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Requirement summary:
-- 1. Request is invalid: Wrong json, parameters of wrong type, string parameters with empty values or whitespace as the
-- only symbol, out of bounds, wrong characters, missing mandatory parameters
-- 2. SDL responds INVALID_DATA, success:false
--
-- Description:
-- SDL receives GetWayPoints request to not reqistered application
--
-- Steps:
-- SDL receives GetWayPoints request to not reqistered application
--
-- Expected:
-- SDL responds APPLICATION_NOT_REGISTERED, success:false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local mobileSession = require('mobile_session')

--[[ Local Functions ]]
local function GetWayPoints(self)
	local params = {
	    wayPointType = "ALL"
	}
    local cid = self.mobileSession2:SendRPC("GetWayPoints", params)
    EXPECT_HMICALL("Navigation.GetWayPoints")
    :Times(0)
    self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
    common.DelayedExp()
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
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Start session", CreationNewSession)

runner.Title("Test")
runner.Step("GetWayPoints_APPLICATION_NOT_REGISTERED", GetWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
