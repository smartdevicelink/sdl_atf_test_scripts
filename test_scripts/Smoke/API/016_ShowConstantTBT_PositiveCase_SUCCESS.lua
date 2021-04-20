---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: ShowConstantTBT
-- Item: Happy path
--
-- Requirement summary:
-- [ShowConstantTBT] SUCCESS: getting SUCCESS:Navigation.ShowConstantTBT()
--
-- Description:
-- Mobile application sends valid ShowConstantTBT request and gets Navigation.ShowConstantTBT "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests ShowConstantTBT with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if Navigation interface is available on HMI
-- SDL checks if ShowConstantTBT is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the Navigation part of request with allowed parameters to HMI
-- SDL receives Navigation part of response from HMI with "SUCCESS" result code
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
  navigationText1 = "navigationText1",
  navigationText2 = "navigationText2",
  eta = "12:34",
  totalDistance = "100miles",
  timeToDestination = "10 minutes",
  turnIcon = {
    value = "icon.png",
    imageType = "DYNAMIC",
  },
  nextTurnIcon = {
    value = "icon.png",
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
        value = "icon.png",
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
  pParams.responseUiParams.turnIcon.value = common.getPathToFileInAppStorage(pParams.requestParams.turnIcon.value)
  pParams.responseUiParams.nextTurnIcon.value = common.getPathToFileInAppStorage(pParams.requestParams.nextTurnIcon.value)
  pParams.responseUiParams.softButtons[1].image.value = common.getPathToFileInAppStorage(pParams.requestParams.softButtons[1].image.value)
  common.getHMIConnection():ExpectRequest("Navigation.ShowConstantTBT", pParams.responseUiParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, {putFileParams})

runner.Title("Test")
runner.Step("ShowConstantTBT Positive Case", showConstantTBT, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
