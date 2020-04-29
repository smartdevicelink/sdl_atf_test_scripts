---------------------------------------------------------------------------------------------------
-- User story: MobileVersioning Legacy App
-- Use case: CreateInteractionChoiceSet
-- Item: Happy path
--
-- Requirement summary:
-- [CreateInteractionChoiceSet] INVALID_DATA
--
-- Description:
-- Mobile application sends valid CreateInteractionChoiceSet request where
-- only some choices have vrCommands

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests CreateInteractionChoiceSet with mixed vrCommands

-- Expected:
-- SDL invalidates parameters of the request
-- SDL responds with (resultCode: INVALID_DATA, success:false) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
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
	    menuName = "Choice1001",
	    vrCommands = {
	      "Choice1001"
	    },
	    image = {
	      value = "icon.png",
	      imageType = "DYNAMIC"
	    }
	  },
	  {
	    choiceID = 1002,
	    menuName = "Choice1002",
	    image = {
	      value = "icon.png",
	      imageType = "DYNAMIC"
	    }
	  }
	}
}

--[[ Local Functions ]]
local function createInteractionChoiceSet_mixedVR(params)
	local cid = commonSmoke.getMobileSession():SendRPC("CreateInteractionChoiceSet", params)
	commonSmoke.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})

runner.Title("Test")
runner.Step("CreateInteractionChoiceSet mixed VR Commands INVALID_DATA Case", createInteractionChoiceSet_mixedVR, {requestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
