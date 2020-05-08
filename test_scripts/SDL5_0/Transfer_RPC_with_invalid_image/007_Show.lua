---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests Show with image that is absent on file system
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
  mainField1 = "a",
  mainField2 = "a",
  mainField3 = "a",
  mainField4 = "a",
  statusBar = "a",
  mediaClock = "a",
  mediaTrack = "a",
  alignment = "CENTERED",
  graphic = {
    imageType = "DYNAMIC",
    value = "missed_icon.png"
  },
  secondaryGraphic = {
    imageType = "DYNAMIC",
    value = "missed_icon.png"
  },
}

local responseUiParams = {
  showStrings = {
    {
      fieldName = "mainField1",
      fieldText = requestParams.mainField1
    },
    {
      fieldName = "mainField2",
      fieldText = requestParams.mainField2
    },
    {
      fieldName = "mainField3",
      fieldText = requestParams.mainField3
    },
    {
      fieldName = "mainField4",
      fieldText = requestParams.mainField4
    },
    {
      fieldName = "mediaClock",
      fieldText = requestParams.mediaClock
    },
    {
      fieldName = "mediaTrack",
      fieldText = requestParams.mediaTrack
    },
    {
      fieldName = "statusBar",
      fieldText = requestParams.statusBar
    }
  },
  alignment = requestParams.alignment,
  graphic = {
    imageType = requestParams.graphic.imageType,
    value = common.getPathToFileInStorage(requestParams.graphic.value)
  },
  secondaryGraphic = {
    imageType = requestParams.secondaryGraphic.imageType,
    value = common.getPathToFileInStorage(requestParams.secondaryGraphic.value)
  }
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
}

--[[ Local Functions ]]
local function Show(pParams)
  local cid = common.getMobileSession():SendRPC("Show", pParams.requestParams)
  pParams.responseUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.Show", pParams.responseUiParams)
  :Do(function(_,data)
      common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS",
    info = "Requested image(s) not found" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Show with invalid image", Show, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
