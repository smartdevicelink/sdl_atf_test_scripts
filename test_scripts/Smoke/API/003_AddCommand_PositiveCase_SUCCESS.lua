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
    if data.params.grammarID ~= nil then
      return true
    else
      return false, "grammarID should not be empty"
    end
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

runner.Title("Test")
runner.Step("AddCommand Positive Case", addCommand, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
