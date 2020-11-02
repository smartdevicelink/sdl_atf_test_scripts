---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1306
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. Send SetGlobalProperties from mobile (helpPrompt, timeoutPrompt, vrHelpTitle, vrHelp)
-- 2. Stop smartDeviceLinkCore in terminal (through ctrl+c) and do not exit from mobile app
-- 3. Start smartDeviceLinkCore and HMI
-- 4. Mobile App is registered and activated
-- 5. Send SetGlobalProperties from mobile (helpPrompt, timeoutPrompt, vrHelpTitle, vrHelp)
-- 6. Send ResetGlobalProperties from mobile (helpPrompt, timeoutPrompt, vrHelpTitle, vrHelp)
--
-- SDL does:
--  - send to HMI UI.SetGlobalProperties("vrHelpTitle", "vrHelp") with default values
--  - send to HMI TTS.SetGlobalProperties with "helpPrompt" parameter that should be reset to default value
--    (smartDeviceLink.ini file contains default values for "helpPrompt"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
	helpPrompt = {{ text = "Help prompt", type = "TEXT" }},
	timeoutPrompt = {{ text = "Timeout prompt", type = "TEXT" }},
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
local function splitString(pInputStr, pSep)
  if pSep == nil then
    pSep = "%s"
  end
  local out, i = {}, 1
  for str in string.gmatch(pInputStr, "([^" .. pSep .. "]+)") do
    out[i] = str
    i = i + 1
  end
  return out
end

local function getResetGlobalPropertiesParams()
	local uiParams = {
		vrHelpTitle = common.sdl.getSDLIniParameter("HelpTitle"),
		vrHelp = {{ position = 1, text = common.getConfigAppParams().appName }}
	}

	local delimiter = common.sdl.getSDLIniParameter("TTSDelimiter")
	local paramHP = splitString(common.sdl.getSDLIniParameter("HelpPromt"), delimiter)
	local paramTP = splitString(common.sdl.getSDLIniParameter("TimeOutPromt"), delimiter)
	local helpPromptArray = {}
	local timeoutPromptArray = {}

	if next(paramHP) then
		for i = 1, #paramHP do
			helpPromptArray[i] = { text = paramHP[i] .. delimiter, type = "TEXT" }
		end
	end

	if next(paramTP) then
		for i = 1, #paramTP do
			timeoutPromptArray[i] = { text = paramTP[i] .. delimiter, type = "TEXT" }
		end
	end

	local ttsParams = {
		helpPrompt = helpPromptArray,
		timeoutPrompt = timeoutPromptArray
	}
	return uiParams, ttsParams
end

local function sendSetGlobalProperties(pParams)
	local cid = common.mobile.getSession():SendRPC("SetGlobalProperties", pParams.requestParams)

	pParams.UiParams.appID = common.getHMIAppId()
	common.hmi.getConnection():ExpectRequest("UI.SetGlobalProperties", pParams.UiParams)
	:Do(function(_,data)
		common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	pParams.TtsParams.appID = common.getHMIAppId()
	common.hmi.getConnection():ExpectRequest("TTS.SetGlobalProperties", pParams.TtsParams)
	:Do(function(_,data)
		common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	common.mobile.getSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	common.mobile.getSession():ExpectNotification("OnHashChange")
end

local function sendResetGlobalProperties()
	local requesUIparams, requesTTSparams = getResetGlobalPropertiesParams()

	local cid = common.mobile.getSession():SendRPC("ResetGlobalProperties", {
		properties = { "VRHELPTITLE", "HELPPROMPT", "TIMEOUTPROMPT", "VRHELPITEMS" }
	})

	common.hmi.getConnection():ExpectRequest("UI.SetGlobalProperties", requesUIparams)
	:Do(function(_,data)
		common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	common.hmi.getConnection():ExpectRequest("TTS.SetGlobalProperties", requesTTSparams)
	:Do(function(_,data)
		common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	common.mobile.getSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	common.mobile.getSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.app.register)
runner.Step("Activate App", common.app.activate)

runner.Title("Test")
runner.Step("Send SetGlobalProperties", sendSetGlobalProperties, { allParams })
runner.Step("Stop SDL", StopSDL)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.app.registerNoPTU)
runner.Step("Activate App", common.app.activate)
runner.Step("Send SetGlobalProperties", sendSetGlobalProperties, { allParams })
runner.Step("Send ResetGlobalProperties", sendResetGlobalProperties)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
