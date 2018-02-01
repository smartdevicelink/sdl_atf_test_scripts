---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: RegisterAppInterface
-- Item: Happy path
--
-- Requirement summary:
-- [RegisterAppInterface] SUCCESS: getting SUCCESS:RegisterAppInterface() during reregistration
--
-- Description:
-- Mobile application sends valid RegisterAppInterface request after unregistration and
-- gets RegisterAppInterface "SUCCESS" response from SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests RegisterAppInterface

-- Expected:
-- SDL checks if RegisterAppInterface is allowed by Policies
-- SDL sends the BasicCommunication notification to HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local requestParams = {
	syncMsgVersion = {
		majorVersion = 2,
		minorVersion = 2,
	},
	appName = "SyncProxyTester",
	ttsName = {
		{
			text ="SyncProxyTester",
			type ="TEXT",
		},
	},
	ngnMediaScreenAppName = "SPT",
	vrSynonyms = {
		"VRSyncProxyTester",
	},
	isMediaApplication = true,
	languageDesired = "EN-US",
	hmiDisplayLanguageDesired = "EN-US",
	appHMIType = {
		"DEFAULT",
	},
	appID = "123456",
	deviceInfo = {
		hardware = "hardware",
		firmwareRev = "firmwareRev",
		os = "os",
		osVersion = "osVersion",
		carrier = "carrier",
		maxNumberRFCOMMPorts = 5
	}
}

local function SetNotificationParams()
	local notificationParams = {
		application = {}
	}
	notificationParams.application.appName = requestParams.appName
	notificationParams.application.ngnMediaScreenAppName = requestParams.ngnMediaScreenAppName
	notificationParams.application.isMediaApplication = requestParams.isMediaApplication
	notificationParams.application.hmiDisplayLanguageDesired = requestParams.hmiDisplayLanguageDesired
	notificationParams.application.appType = requestParams.appHMIType
	notificationParams.application.deviceInfo = {
		name = commonSmoke.getDeviceName(),
		id = commonSmoke.getDeviceMAC(),
		transportType = "WIFI",
		isSDLAllowed = true
	}
	notificationParams.application.policyAppID = requestParams.appID
	notificationParams.ttsName = requestParams.ttsName
	notificationParams.vrSynonyms = requestParams.vrSynonyms
	return notificationParams
end

--[[ Local Functions ]]
local function unregisterAppInterface(self)
	local cid = self.mobileSession1:SendRPC("UnregisterAppInterface", { })
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
		{ appID = commonSmoke.getHMIAppId(), unexpectedDisconnect = false })
	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function RegisterAppInterface(self)
	local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface", requestParams)
	local notificationParams = SetNotificationParams()
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", notificationParams)
	self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS" })
	self.mobileSession1:ExpectNotification("OnHMIStatus",
		{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
	self.mobileSession1:ExpectNotification("OnPermissionsChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("UnregisterAppInterface Positive Case", unregisterAppInterface)

runner.Title("Test")
runner.Step("RegisterAppInterface Positive Case", RegisterAppInterface)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
