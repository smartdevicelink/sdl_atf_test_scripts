---------------------------------------------------------------------------------------------------
-- User story: MobileVersioning Legacy App
-- Use case: CreateInteractionChoiceSet
-- Item: Happy path
--
-- Requirement summary:
-- [CreateInteractionChoiceSet] SUCCESS
--
-- Description:
-- Mobile application sends valid CreateInteractionChoiceSet request with
-- {interactionChoiceSetID, ChoiceSet: [(choiceID1, vrCommands, params),
-- (choiceID2, vrCommands, params)] and SDL successfully stores UI-related
-- choices and gets successful responses to corresponding VR.AddCommands
-- (VR-related choices) from HMI.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests CreateInteractionChoiceSet with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if VR interface is available on HMI
-- SDL checks if CreateInteractionChoiceSet is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the VR.AddCommand with allowed parameters to HMI
-- SDL receives successful responses to corresponding VR.AddCommands from HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 3
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

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

local responseVrParams = {
	cmdID = requestParams.interactionChoiceSetID,
	type = "Choice",
	vrCommands = requestParams.vrCommands
}

local allParams = {
	requestParams = requestParams,
	responseVrParams = responseVrParams
}


--[[ Local Functions ]]
local function createInteractionChoiceSet(params)
	local cid = commonSmoke.getMobileSession():SendRPC("CreateInteractionChoiceSet", params.requestParams)

	params.responseVrParams.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("VR.AddCommand", params.responseVrParams)
	:Do(function(_,data)
		commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if data.params.grammarID ~= nil then
			return true
		else
			return false, "grammarID should not be empty"
		end
	end)

	commonSmoke.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	commonSmoke.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})

runner.Title("Test")
runner.Step("CreateInteractionChoiceSet Positive Case", createInteractionChoiceSet, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
