---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: DeleteInteractionChoiceSet
-- Item: Happy path
--
-- Requirement summary:
-- [DeleteInteractionChoiceSet] SUCCESS choiceSet removal
--
-- Description:
-- Mobile application sends valid DeleteInteractionChoiceSet request to SDL
-- and interactionChoiceSet with <interactionChoiceSetID> was successfully
-- removed on SDL and HMI for the application.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. Choice set with <interactionChoiceSetID> is created

-- Steps:
-- appID requests DeleteInteractionChoiceSet request with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if VR interface is available on HMI
-- SDL checks if DeleteInteractionChoiceSet is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the VR.DeleteCommand with allowed parameters to HMI
-- SDL receives successful responses to corresponding VR.DeleteCommand from HMI
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

local createRequestParams = {
	interactionChoiceSetID = 1001,
	choiceSet = {
		{
			choiceID = 1001,
			menuName ="Choice1001",
			vrCommands = {
				"Choice1001"
			},
			image = {
				value ="icon.png",
				imageType ="DYNAMIC"
			}
		}
	}
}

local createResponseVrParams = {
	cmdID = createRequestParams.interactionChoiceSetID,
	type = "Choice",
	vrCommands = createRequestParams.vrCommands
}

local createAllParams = {
	requestParams = createRequestParams,
	responseVrParams = createResponseVrParams
}

local deleteRequestParams = {
	interactionChoiceSetID = createRequestParams.interactionChoiceSetID
}

local deleteResponseVrParams = {
	cmdID = createRequestParams.interactionChoiceSetID,
	type = "Choice"
}

local deleteAllParams = {
	requestParams = deleteRequestParams,
	responseVrParams = deleteResponseVrParams
}

--[[ Local Functions ]]
local function createInteractionChoiceSet(params, self)
	local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet", params.requestParams)

	params.responseVrParams.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("VR.AddCommand", params.responseVrParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if data.params.grammarID ~= nil then
			deleteResponseVrParams.grammarID = data.params.grammarID
			return true
		else
			return false, "grammarID should not be empty"
		end
	end)

	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	self.mobileSession1:ExpectNotification("OnHashChange")
end

local function deleteInteractionChoiceSet(params, self)
	local cid = self.mobileSession1:SendRPC("DeleteInteractionChoiceSet", params.requestParams)

	params.responseVrParams.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("VR.DeleteCommand", params.responseVrParams)
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
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSet, {createAllParams})

runner.Title("Test")
runner.Step("DeleteInteractionChoiceSet Positive Case", deleteInteractionChoiceSet, {deleteAllParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
