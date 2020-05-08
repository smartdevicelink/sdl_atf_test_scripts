---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests ShowConstantTBT with image that is absent on file system
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
  navigationText1 = "navigationText1",
  navigationText2 = "navigationText2",
  eta = "12:34",
  totalDistance = "100miles",
  timeToDestination = "10 minutes",
  turnIcon = {
    value = "missed_icon.png",
    imageType = "DYNAMIC",
  },
  nextTurnIcon = {
    value = "missed_icon.png",
    imageType = "DYNAMIC",
  },
  distanceToManeuver = 50.5,
  distanceToManeuverScale = 100.5,
  maneuverComplete = false,
  softButtons = {
    {
      type = "BOTH",
      text = "Close",
      image = {
        value = "missed_icon.png",
        imageType = "DYNAMIC",
      },
      isHighlighted = true,
      softButtonID = 44,
      systemAction ="DEFAULT_ACTION",
    },
  },
}

local responseUiParams = {
  navigationTexts = {
    {
      fieldName = "navigationText1",
      fieldText = requestParams.navigationText1
    },
    {
      fieldName = "navigationText2",
      fieldText = requestParams.navigationText2
    },
    {
      fieldName = "ETA",
      fieldText = requestParams.eta
    },
    {
      fieldName = "totalDistance",
      fieldText = requestParams.totalDistance
    },
    {
      fieldName = "timeToDestination",
      fieldText = requestParams.timeToDestination
    }
  },
  turnIcon = requestParams.turnIcon,
  nextTurnIcon = requestParams.nextTurnIcon,
  distanceToManeuver = requestParams.distanceToManeuver,
  distanceToManeuverScale = requestParams.distanceToManeuverScale,
  maneuverComplete = requestParams.maneuverComplete,
  softButtons = requestParams.softButtons
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams
}

--[[ Local Functions ]]
local function showConstantTBT(pParams)
  local cid = common.getMobileSession():SendRPC("ShowConstantTBT", pParams.requestParams)
  pParams.responseUiParams.appID = common.getHMIAppId()
  pParams.responseUiParams.turnIcon.value = common.getPathToFileInStorage(pParams.requestParams.turnIcon.value)
  pParams.responseUiParams.nextTurnIcon.value = common.getPathToFileInStorage(pParams.requestParams.nextTurnIcon.value)
  pParams.responseUiParams.softButtons[1].image.value = common.getPathToFileInStorage(pParams.requestParams.softButtons[1].image.value)
  EXPECT_HMICALL("Navigation.ShowConstantTBT", pParams.responseUiParams)
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
runner.Step("ShowConstantTBT with invalid image", showConstantTBT, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
