---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1833
--
-- Description:
-- Precondition:
-- In case:
-- Change HMI to not respond to VR.DeleteCommand
-- Create Interaction choice set
-- Delete Interaction choice set
-- Expected result:
-- Mobile should receive error from core (Timed out or generic error)
-- Actual result:
-- Mobile receives success from core.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

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
local function putFile(params)
    local cid = common.getMobileSession():SendRPC("PutFile", params.requestParams, params.filePath)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local function createInteractionChoiceSet(params)
	local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", params.requestParams)
	params.responseVrParams.appID = common.getHMIAppId()
	EXPECT_HMICALL("VR.AddCommand", params.responseVrParams)
	:Do(function(_,data)
		common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if data.params.grammarID ~= nil then
			deleteResponseVrParams.grammarID = data.params.grammarID
			return true
		else
			return false, "grammarID should not be empty"
		end
	end)

	common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	common.getMobileSession():ExpectNotification("OnHashChange")
end

local function deleteInteractionChoiceSet(params)
	local cid = common.getMobileSession():SendRPC("DeleteInteractionChoiceSet", params.requestParams)
	params.responseVrParams.appID = common.getHMIAppId()
	EXPECT_HMICALL("VR.DeleteCommand", params.responseVrParams)
	:Do(function(_,_)
		-- HMI does not respond
	end)

	common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", putFile, {putFileParams})
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSet, {createAllParams})

runner.Title("Test")
runner.Step("DeleteInteractionChoiceSet", deleteInteractionChoiceSet, {deleteAllParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
