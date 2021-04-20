---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests SetGlobalProperties with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS, message: “Requested image(s) not found”) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  helpPrompt = {
    {
      text = "Help prompt",
      type = "TEXT"
    }
  },
  timeoutPrompt = {
    {
      text = "Timeout prompt",
      type = "TEXT"
    }
  },
  vrHelpTitle = "VR help title",
  vrHelp = {
    {
      position = 1,
      image = {
        value = "missed_icon.png",
        imageType = "DYNAMIC"
      },
      text = "VR help item"
    }
  },
  menuTitle = "Menu Title",
  menuIcon = {
    value = "missed_icon.png",
    imageType = "DYNAMIC"
  },
  keyboardProperties = {
    keyboardLayout = "QWERTY",
    keypressMode = "SINGLE_KEYPRESS",
    limitedCharacterList = {"a"},
    language = "EN-US",
    autoCompleteList = { "Daemon", "Freedom" }
  }
}

local responseUiParams = {
  vrHelpTitle = requestParams.vrHelpTitle,
  vrHelp = requestParams.vrHelp,
  menuTitle = requestParams.menuTitle,
  menuIcon = requestParams.menuIcon,
  keyboardProperties = requestParams.keyboardProperties
}

local responseTtsParams = {
  timeoutPrompt = requestParams.timeoutPrompt,
  helpPrompt = requestParams.helpPrompt
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
  responseTtsParams = responseTtsParams
}

--[[ Local Functions ]]
local function setGlobalProperties(pParams)
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", pParams.requestParams)

  pParams.responseUiParams.appID = common.getHMIAppId()
  pParams.responseUiParams.vrHelp[1].image.value = common.getPathToFileInStorage("missed_icon.png")
  pParams.responseUiParams.menuIcon.value = common.getPathToFileInStorage("missed_icon.png")
  EXPECT_HMICALL("UI.SetGlobalProperties", pParams.responseUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
  end)

  pParams.responseTtsParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("TTS.SetGlobalProperties", pParams.responseTtsParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS",
    info = "Requested image(s) not found"})
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetGlobalProperties with invalid image", setGlobalProperties, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
