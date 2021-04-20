---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests createInteractionChoiceSet with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS) to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  interactionChoiceSetID = 1001,
  choiceSet = {
    {
      choiceID = 1001,
      menuName ="Choice1001",
      vrCommands = {
        "Choice1001"
      },
      image = {
        value ="missed_icon.png",
        imageType ="DYNAMIC"
      }
    }
  }
}

local responseVrParams = {
  cmdID = requestParams.interactionChoiceSetID,
  type = "Choice",
  vrCommands = requestParams.vrCommands
}

local allParams = {
  requestParams = requestParams,
  responseVrParams = responseVrParams
}

--[[ Local Functions ]]
local function createInteractionChoiceSet(pParams)
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", pParams.requestParams)

  pParams.responseVrParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("VR.AddCommand", pParams.responseVrParams)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    if data.params.grammarID ~= nil then
      return true
    else
      return false, "grammarID should not be empty"
    end
  end)

  common.getMobileSession():ExpectResponse(cid, { resultCode = "WARNINGS", success = true })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("CreateInteractionChoiceSet with invalid image", createInteractionChoiceSet, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
