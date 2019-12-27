---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- 1. Request is sent in NONE, BACKGROUND, FULL, LIMITED levels
-- 2. SDL responds DISALLOWED, success:false to request in NONE level and SUCCESS, success:true in other ones
--
-- Description:
-- App requests SendLocation in different HMI levels
--
-- Steps:
-- SDL receives SendLocation request in NONE, BACKGROUND, FULL, LIMITED
--
-- Expected:
-- SDL responds DISALLOWED, success:false in NONE level, SUCCESS, success:true in BACKGROUND, FULL, LIMITED levels
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

--[[ Local Variables ]]
local requestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1
}

--[[ Local Functions ]]
local function sendLocationDisallowed(params, self)
    local cid = self.mobileSession2:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation")
    :Times(0)

    self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
    commonSendLocation.delayedExp()
end

local function sendLocationSuccess(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)
    params.appID = commonSendLocation.getHMIAppId()

    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function BringAppToLimitedLevel(self)
    local appIDval = commonSendLocation.getHMIAppId(1)
	self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{ appID = appIDval })

	self.mobileSession1:ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED" })
end

local function BringAppToBackgroundLevel(self)
	commonSendLocation.activateApp(2, self)

	self.mobileSession1:ExpectNotification("OnHMIStatus",{ hmiLevel = "BACKGROUND" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU first app", commonSendLocation.registerApplicationWithPTU)
runner.Step("RAI, PTU second app", commonSendLocation.registerApplicationWithPTU, { 2 })
runner.Step("Activate first App", commonSendLocation.activateApp)

runner.Title("Test")
runner.Step("SendLocation_in_NONE", sendLocationDisallowed, { requestParams })
runner.Step("SendLocation_in_FULL", sendLocationSuccess, { requestParams })
runner.Step("Bring_app_to_limited", BringAppToLimitedLevel)
runner.Step("SendLocation_in_LIMITED", sendLocationSuccess, { requestParams })
runner.Step("Bring_app_to_background", BringAppToBackgroundLevel)
runner.Step("SendLocation_in_BACKGROUND", sendLocationSuccess, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
