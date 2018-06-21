---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1306
--
-- Precondition:
--
-- Delete app_info.dat file.
-- SDL started. Application is registered and activated on HMI.
-- Description:
-- Steps to reproduce:
-- 1) Send SetGlobalProperties from mobile (helpPrompt, timeoutPrompt, vrHelpTitle, vrHelp). ==>successfully set
-- 2) Stop smartDeviceLinkCore in terminal (through ctrl+c) and do not exit from mobile app.
-- 3) Start smartDeviceLinkCore and HMI.
-- 4) Mobile App is registered and activated (HMI lvl FULL)
-- 5) Send SetGlobalProperties from mobile (helpPrompt, timeoutPrompt, vrHelpTitle, vrHelp). ==>successfully set
-- 6) Send ResetGlobalProperties from mobile (helpPrompt, timeoutPrompt, vrHelpTitle, vrHelp)
-- Expected result:
-- 1) SDL should send to HMI UI.SetGlobalProperties("vrHelpTitle", "vrHelp") with default values.
-- 2) SDL should send to HMI TTS.SetGlobalProperties with "helpPrompt" parameter that should be reset to default value
--    (smartDeviceLink.ini file contains default values for "helpPrompt"
-- Actual result:
-- 1) SDL sends to HMI UI.SetGlobalProperties(vrHelpTitle) without vrHelp - not OK
-- 2) SDL sends to HMI TTS.SetGlobalProperties("helpPrompt":[ ]) - empty array - not OK.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local actions = require("user_modules/sequences/actions")

--[[ Local Variables ]]
local requestParams = {
	helpPrompt = {{ text = "Help prompt", type = "TEXT" }},
	timeoutPrompt = {{	text = "Timeout prompt", type = "TEXT" }},
	vrHelpTitle = "VR help title",
	vrHelp = {{	position = 1, text = "VR help item" }}
}

local UiParams = {
	vrHelpTitle = requestParams.vrHelpTitle,
	vrHelp = requestParams.vrHelp,
}

local TtsParams = {
	timeoutPrompt = requestParams.timeoutPrompt,
	helpPrompt = requestParams.helpPrompt
}

local allParams = {
	requestParams = requestParams,
	UiParams = UiParams,
	TtsParams = TtsParams
}

--[[ Local Functions ]]
local function getValueFromIniFile(path_to_ini, parameter_name)
	local f = assert(io.open(path_to_ini, "r"))
	local fileContent = f:read("*all")
	local ParameterValue
	ParameterValue = string.match(fileContent, parameter_name .. " =.- (.-)\n")
	f:close()
	return ParameterValue
end

local pathToIniFile = commonPreconditions:GetPathToSDL() .. "smartDeviceLink.ini"

local requesUIparams = {
	vrHelpTitle = getValueFromIniFile(pathToIniFile, "HelpTitle"),
	vrHelp = {{ position = 1, text = actions.getConfigAppParams(pAppId).appName }}
}

local paramHP = getValueFromIniFile(pathToIniFile, "HelpPromt")
local paramTP = getValueFromIniFile(pathToIniFile, "TimeOutPromt")

local requesTTSparams = {
	helpPrompt = {{ text = paramHP[1], type = "TEXT"}, {text = paramHP[2], type = "TEXT"}},
	timeoutPrompt = {{ text = paramTP[1], type = "TEXT"}, {text = paramTP[2], type = "TEXT"}}
}

local function setGlobalPropertiesSUCCES(params, self)
	local cid = self.mobileSession1:SendRPC("SetGlobalProperties", params.requestParams)

	params.UiParams.appID = common.getHMIAppId()
	EXPECT_HMICALL("UI.SetGlobalProperties", params.UiParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	params.TtsParams.appID = common.getHMIAppId()
	EXPECT_HMICALL("TTS.SetGlobalProperties", params.TtsParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	self.mobileSession1:ExpectNotification("OnHashChange")
end

local function sdlStop(self)
	StopSDL()
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = common.getHMIAppId(), unexpectedDisconnect = true })
	self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", {{}})
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
end

local function ResetGlobalProperties(self)
	local cid = self.mobileSession1:SendRPC("ResetGlobalProperties", {
		properties = { "VRHELPTITLE", "HELPPROMPT", "TIMEOUTPROMPT", "VRHELPITEMS" }
	})
	EXPECT_HMICALL("UI.SetGlobalProperties", requesUIparams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	EXPECT_HMICALL("TTS.SetGlobalProperties", requesTTSparams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	self.mobileSession1:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("Send SetGlobalProperties", setGlobalPropertiesSUCCES, { allParams })
runner.Step("Stop SDL", sdlStop)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_n)
runner.Step("Activate App", common.activate_app)
runner.Step("Send SetGlobalProperties", setGlobalPropertiesSUCCES, { allParams })
runner.Step("Send ResetGlobalProperties", ResetGlobalProperties)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
