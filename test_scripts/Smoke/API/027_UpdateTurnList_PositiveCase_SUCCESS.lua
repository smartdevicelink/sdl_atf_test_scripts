---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: UpdateTurnList
-- Item: Happy path
--
-- Requirement summary:
-- [UpdateTurnList] SUCCESS: getting SUCCESS:VehicleInfo.UpdateTurnList()
--
-- Description:
-- Mobile application sends valid UpdateTurnList request and gets Navigation.UpdateTurnList "SUCCESS"
-- response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests UpdateTurnList with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if Navigation interface is available on HMI
-- SDL checks if UpdateTurnList is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the Navigation part of request with allowed parameters to HMI
-- SDL receives Navigation part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

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
  turnList = {
    {
      navigationText = "Text",
      turnIcon = {
        value = "icon.png",
        imageType = "DYNAMIC",
      }
    }
  },
  softButtons = {
    {
      type = "BOTH",
      text = "Close",
      image = {
        value = "icon.png",
        imageType = "DYNAMIC",
      },
      isHighlighted = true,
      softButtonID = 111,
      systemAction = "DEFAULT_ACTION",
    }
  }
}

local responseUiParams = commonFunctions:cloneTable(requestParams)
responseUiParams.turnList[1].navigationText = {
  fieldText = requestParams.turnList[1].navigationText,
  fieldName = "navigationText"
}
responseUiParams.turnList[1].turnIcon.value = commonSmoke.getPathToFileInStorage(requestParams.turnList[1].turnIcon.value)
responseUiParams.softButtons[1].image.value = commonSmoke.getPathToFileInStorage(requestParams.softButtons[1].image.value)

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
}

--[[ Local Functions ]]
local function updateTurnList(pParams, self)
  local cid = self.mobileSession1:SendRPC("UpdateTurnList", pParams.requestParams)
  EXPECT_HMICALL("Navigation.UpdateTurnList", pParams.responseUiParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS")
  end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, { putFileParams })

runner.Title("Test")
runner.Step("UpdateTurnList Positive Case", updateTurnList, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
