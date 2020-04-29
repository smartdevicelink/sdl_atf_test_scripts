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
local common = require('test_scripts/Smoke/commonSmoke')

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
local function createInteractionChoiceSet(pParams)
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", pParams.requestParams)

  pParams.responseVrParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("VR.AddCommand", pParams.responseVrParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_, data)
      if data.params.grammarID ~= nil then
        deleteResponseVrParams.grammarID = data.params.grammarID
        return true
      else
        return false, "grammarID should not be empty"
      end
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function deleteInteractionChoiceSet(pParams)
  local cid = common.getMobileSession():SendRPC("DeleteInteractionChoiceSet", pParams.requestParams)

  pParams.responseVrParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("VR.DeleteCommand", pParams.responseVrParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { putFileParams })
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSet, { createAllParams })

runner.Title("Test")
runner.Step("DeleteInteractionChoiceSet Positive Case", deleteInteractionChoiceSet, { deleteAllParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
