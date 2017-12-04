---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: DeleteCommand
-- Item: Happy path
--
-- Requirement summary:
-- [DeleteCommand] SUCCESS: getting SUCCESS from VR.DeleteCommand() and UI.DeleteCommand()
--
-- Description:
-- Mobile application sends DeleteCommand request for a command created with both "vrCommands"
-- and "menuParams", and SDL gets VR and UI.DeleteCommand "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. Command with both vrCommands and menuParams was created

-- Steps:
-- appID requests DeleteCommand with the both vrCommands and menuParams

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if VR interface is available on HMI
-- SDL checks if DeleteCommand is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL transfers the VR part of request with allowed parameters to HMI
-- SDL receives UI and VR part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local putFileParams = {
	requestParams = {
	    syncFileName = 'icon.png',
	    fileType = "GRAPHIC_PNG",
	    persistentFile = false,
	    systemFile = false
	},
	filePath = "files/icon.png"
}

local addCommandRequestParams = {
	cmdID = 11,
	menuParams = {
		position = 0,
		menuName ="Commandpositive"
	},
	vrCommands = {
		"VRCommandonepositive",
		"VRCommandonepositivedouble"
	},
	cmdIcon = {
		value ="icon.png",
		imageType ="DYNAMIC"
	}
}

local addCommandGrammarID = 0

local addCommandResponseUiParams = {
	cmdID = addCommandRequestParams.cmdID,
	cmdIcon = addCommandRequestParams.cmdIcon,
	menuParams = addCommandRequestParams.menuParams
}

local addCommandResponseVrParams = {
	cmdID = addCommandRequestParams.cmdID,
	type = "Command",
	vrCommands = addCommandRequestParams.vrCommands
}

local addCommandAllParams = {
	requestParams = addCommandRequestParams,
	responseUiParams = addCommandResponseUiParams,
	responseVrParams = addCommandResponseVrParams
}

local deleteCommandRequestParams = {
	cmdID = addCommandRequestParams.cmdID
}

--[[ Local Functions ]]
local function addCommand(params, self)
	local cid = self.mobileSession1:SendRPC("AddCommand", params.requestParams)

	params.responseUiParams.appID = commonSmoke.getHMIAppId()
	params.responseUiParams.cmdIcon.value = commonSmoke.getPathToFileInStorage("icon.png")
	EXPECT_HMICALL("UI.AddCommand", params.responseUiParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	params.responseVrParams.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("VR.AddCommand", params.responseVrParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if data.params.grammarID == nil then
			return false, "grammarID should not be empty"
		end
		addCommandGrammarID = data.params.grammarID
		return true
	end)

	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	self.mobileSession1:ExpectNotification("OnHashChange")
end

local function deleteCommand(params, self)
	local cid = self.mobileSession1:SendRPC("DeleteCommand", params)

	params.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("UI.DeleteCommand", params)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	local responseVrParams = {
		cmdID = params.cmdID,
		grammarID = addCommandGrammarID
	}
	EXPECT_HMICALL("VR.DeleteCommand", responseVrParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	self.mobileSession1:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})
runner.Step("AddCommand", addCommand, {addCommandAllParams})

runner.Title("Test")
runner.Step("DeleteCommand Positive Case", deleteCommand, {deleteCommandRequestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
