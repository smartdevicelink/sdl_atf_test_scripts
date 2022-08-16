---------------------------------------------------------------------------------------------------
-- Use case: AddCommand
-- Item: Failure from UI portion of request
--
-- Requirement summary:
-- [AddCommand] REJECTED: Getting REJECTED on UI.AddCommand
--
-- Description:
-- Mobile application sends valid AddCommand request with "menuParams" 
-- data and gets "REJECTED" for UI.AddCommand from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- 1. appID requests AddCommand with menuParams
-- 2. SDL transfers the UI part of request with allowed parameters to HMI
-- 3. SDL receives UI part of response from HMI with "REJECTED" result code

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
  menuParams = {
    position = 0,
    menuName = "Commandpositive",
    secondaryText = "Secondary",
    tertiaryText = "Tertiary"
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

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams
}

local uiResponseCode = "REJECTED"

--[[ Local Functions ]]
local function addCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams.requestParams)

  pParams.responseUiParams.appID = common.getHMIAppId()
  pParams.responseUiParams.cmdIcon.value = common.getPathToFileInAppStorage("icon.png")
  pParams.responseUiParams.secondaryImage.value = common.getPathToFileInAppStorage("icon.png")
  common.getHMIConnection():ExpectRequest("UI.AddCommand", pParams.responseUiParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, uiResponseCode, {})
      common.getHMIConnection():ExpectRequest("UI.DeleteCommand", {
        cmdID = pParams.requestParams.cmdID
      }):Times(0)
    end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand", {}):Times(0)

  common.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = uiResponseCode
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
