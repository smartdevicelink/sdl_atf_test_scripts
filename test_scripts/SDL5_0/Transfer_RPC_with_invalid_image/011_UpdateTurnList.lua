---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests UpdateTurnList with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS, message: “Requested image(s) not found”) to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  turnList = {
    {
      navigationText = "Text",
      turnIcon = {
        value = "missed_icon.png",
        imageType = "DYNAMIC",
      }
    }
  },
  softButtons = {
    {
      type = "BOTH",
      text = "Close",
      image = {
        value = "missed_icon.png",
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
  fieldName = "turnText"
}
responseUiParams.turnList[1].turnIcon.value = common.getPathToFileInStorage(requestParams.turnList[1].turnIcon.value)
responseUiParams.softButtons[1].image.value = common.getPathToFileInStorage(requestParams.softButtons[1].image.value)

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
}

--[[ Local Functions ]]
local function updateTurnList(pParams)
  local cid = common.getMobileSession():SendRPC("UpdateTurnList", pParams.requestParams)
  EXPECT_HMICALL("Navigation.UpdateTurnList", pParams.responseUiParams)
  :Do(function(_,data)
    common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS", info =  "Requested image(s) not found"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("UpdateTurnList with invalid image", updateTurnList, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
