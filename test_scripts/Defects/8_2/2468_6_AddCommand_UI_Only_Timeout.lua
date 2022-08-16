---------------------------------------------------------------------------------------------------
-- Use case: AddCommand
-- Item: Timeout from UI portion of request
--
-- Requirement summary:
-- [AddCommand] GENERIC_ERROR: getting GENERIC_ERROR on UI.AddCommand timeout
--
-- Description:
-- Mobile application sends valid AddCommand request with "menuParams" 
-- data and gets no response for UI.AddCommand from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- 1. appID requests AddCommand with menuParams
-- 2. SDL transfers the UI part of request with allowed parameters to HMI
-- 3. SDL does not receive UI part of response

-- Expected:
-- SDL responds with (resultCode: GENERIC_ERROR, success: false) to mobile application
-- SDL sends UI.DeleteCommand based on the original request
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

--[[ Local Functions ]]
local function addCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams.requestParams)

  pParams.responseUiParams.appID = common.getHMIAppId()
  pParams.responseUiParams.cmdIcon.value = common.getPathToFileInAppStorage("icon.png")
  pParams.responseUiParams.secondaryImage.value = common.getPathToFileInAppStorage("icon.png")
  common.getHMIConnection():ExpectRequest("UI.AddCommand", pParams.responseUiParams)
  :Do(function(_, data)
      -- No UI response
      -- common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      common.getHMIConnection():ExpectRequest("UI.DeleteCommand", {
        cmdID = pParams.requestParams.cmdID
      }):Timeout(20000)
    end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand", {}):Times(0)

  common.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = "GENERIC_ERROR"
  }):Timeout(20000)
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
