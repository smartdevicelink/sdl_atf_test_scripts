---------------------------------------------------------------------------------------------------
-- Use case: AddCommand
-- Item: Failure from VR portion of request
--
-- Requirement summary:
-- [AddCommand] REJECTED: Getting REJECTED on VR.AddCommand
--
-- Description:
-- Mobile application sends valid AddCommand request with "vrCommands"
-- data and gets "REJECTED" for VR.AddCommand from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- 1. appID requests AddCommand with vrCommands
-- 2. SDL transfers the VR part of request with allowed parameters to HMI
-- 3. SDL receives VR part of response from HMI with "REJECTED" result code

-- Expected:
-- SDL responds with (resultCode: REJECTED, success: false) to mobile application
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
  vrCommands = {
    "VRCommandonepositive",
    "VRCommandonepositivedouble"
  },
  cmdIcon = {
    value = "icon.png",
    imageType = "DYNAMIC"
  },
  secondaryImage = {
    value = "icon.png",
    imageType = "DYNAMIC"
  }
}

local responseUiParams = {
  cmdID = requestParams.cmdID,
  cmdIcon = requestParams.cmdIcon,
  menuParams = requestParams.menuParams,
  secondaryImage = requestParams.secondaryImage
}

local responseVrParams = {
  cmdID = requestParams.cmdID,
  type = "Command",
  vrCommands = requestParams.vrCommands
}

local allParams = {
  requestParams = requestParams,
  responseVrParams = responseVrParams
}

local vrResponseCode = "REJECTED"

--[[ Local Functions ]]
local function addCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams.requestParams)

  common.getHMIConnection():ExpectRequest("UI.AddCommand", pParams.responseUiParams):Times(0)

  pParams.responseVrParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("VR.AddCommand", pParams.responseVrParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, vrResponseCode, {})
      common.getHMIConnection():ExpectRequest("VR.DeleteCommand", { 
        cmdID = pParams.requestParams.cmdID,
        type = "Command",
        grammarID = data.params.grammarID
      }):Times(0)
    end)
  :ValidIf(function(_, data)
    if data.params.grammarID ~= nil then
      return true
    else
      return false, "grammarID should not be empty"
    end
  end)

  common.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = vrResponseCode
  })
  common.getMobileSession():ExpectNotification("OnHashChange"):Times(0)
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
runner.Step("AddCommand", addCommand, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
