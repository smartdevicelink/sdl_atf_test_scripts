---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2401
--
-- Description: Check that SDL rejects PerformInteraction request with "BOTH" or "VR_ONLY" interaction mode in case
--  RPC is requested with choice with and without VR command
--
-- Steps:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
-- 3. CreateInteractionChoiseSet is added with and without VR command
-- 4. PerformInteraction RPC is requested with created choices and interaction mode is "BOTH" or "VR_ONLY"
-- SDL does:
--  - reject PerformInteraction with "INVALID_DATA" resultCode
-- 5. PerformInteraction RPC is requested with created choices and interaction mode is "MANUAL_ONLY"
-- SDL does:
--  - process the request successfully and send appropriate PerformInteraction requests to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local createICSParams = {
  with_vr = {
    interactionChoiceSetID = 11,
    choiceSet = {
      {
        choiceID = 11,
        menuName = "Choice11",
        vrCommands = { "Choice11" }
      }
    }
  },
  without_vr = {
    interactionChoiceSetID = 10,
    choiceSet = {
      {
        choiceID = 10,
        menuName = "Choice10"
      }
    }
  }
}
local expected = 1
local notExpected = 0

-- [[ Local Functions ]]
local function createInteractionChoiceSet(pParams, pTimes)
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", pParams)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(pTimes)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function performInteraction(pInteractionLayout, pTimes)
  local params = {
    initialText = "Start PerformInteraction",
    interactionMode = pInteractionLayout,
    interactionChoiceSetIDList = {
      createICSParams.with_vr.interactionChoiceSetID,
      createICSParams.without_vr.interactionChoiceSetID
    }
  }
  local cid = common.getMobileSession():SendRPC("PerformInteraction", params)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(pTimes)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(pTimes)
  local result
  if pInteractionLayout == "MANUAL_ONLY" then
    result = { success = true, resultCode = "SUCCESS" }
  else
    result = { success = false, resultCode = "INVALID_DATA", info = "Some choices don't contain VR commands." }
  end
  common.getMobileSession():ExpectResponse(cid, result)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("CreateInteractionChoiceSet with VR command", createInteractionChoiceSet,
  { createICSParams.with_vr, expected })
runner.Step("CreateInteractionChoiceSet without VR command", createInteractionChoiceSet,
  { createICSParams.without_vr, notExpected })

-- [[ Test ]]
runner.Title("Test")
runner.Step("Send PerformInteraction with VR_ONLY mode", performInteraction, { "VR_ONLY", notExpected })
runner.Step("Send PerformInteraction with BOTH mode", performInteraction, { "BOTH", notExpected })
runner.Step("Send PerformInteraction with MANUAL_ONLY mode", performInteraction, { "MANUAL_ONLY", expected })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
