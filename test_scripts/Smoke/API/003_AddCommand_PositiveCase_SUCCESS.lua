---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: AddComand
-- Item: Happy path
--
-- Requirement summary:
-- [AddCommand] SUCCESS: getting SUCCESS on VR and UI.AddCommand()
--
-- Description:
-- Mobile application sends valid AddCommand request with the both "vrCommands"
-- and "menuParams" data and gets "SUCCESS" for the both VR.AddCommand and VR.AddCommand
-- responses from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests AddCommand with the both vrCommands and menuParams

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if VR interface is available on HMI
-- SDL checks if AddCommand is allowed by Policies
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

local requestParams = {
	cmdID = 11,
	menuParams = {
		position = 0,
		menuName ="Commandpositive"
	},
	vrCommands = {
		"VRCommandonepositive",
		"VRCommandonepositivedouble"
	},
	grammarID = 1,
	cmdIcon = {
		value ="icon.png",
		imageType ="DYNAMIC"
	}
}

local responseUiParams = {
	cmdID = requestParams.cmdID,
	cmdIcon = requestParams.cmdIcon,
	menuParams = requestParams.menuParams
}

local responseVrParams = {
	cmdID = requestParams.cmdID,
	type = "Command",
	vrCommands = requestParams.vrCommands
}

local allParams = {
	requestParams = requestParams,
	responseUiParams = responseUiParams,
	responseVrParams = responseVrParams
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
		if data.params.grammarID ~= nil then
			return true
		else
			return false, "grammarID should not be empty"
		end
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

runner.Title("Test")
runner.Step("AddCommand Positive Case", addCommand, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
