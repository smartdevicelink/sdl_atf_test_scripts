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
local function addCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams.requestParams)

  pParams.responseUiParams.appID = common.getHMIAppId()
  pParams.responseUiParams.cmdIcon.value = common.getPathToFileInAppStorage("icon.png")
  common.getHMIConnection():ExpectRequest("UI.AddCommand", pParams.responseUiParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  pParams.responseVrParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("VR.AddCommand", pParams.responseVrParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_, data)
      if data.params.grammarID == nil then
        return false, "grammarID should not be empty"
      end
      addCommandGrammarID = data.params.grammarID
      return true
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function deleteCommand(pParams)
  local cid = common.getMobileSession():SendRPC("DeleteCommand", pParams)

  pParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.DeleteCommand", pParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  local responseVrParams = {
    cmdID = pParams.cmdID,
    grammarID = addCommandGrammarID
  }
  common.getHMIConnection():ExpectRequest("VR.DeleteCommand", responseVrParams)
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
runner.Step("AddCommand", addCommand, { addCommandAllParams })

runner.Title("Test")
runner.Step("DeleteCommand Positive Case", deleteCommand, { deleteCommandRequestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
