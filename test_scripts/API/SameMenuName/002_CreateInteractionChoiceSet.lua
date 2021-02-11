---------------------------------------------------------------------------------------------------
-- Proposal: SDL 0180 Broaden Choice Uniqueness
-- 
-- Description:
--   Mobile shall be able to send a CreateInteractionChoiceSet RPC where two choices within the
--   choice set have identical menuName values.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local cics1Params = {
  interactionChoiceSetID = 499,
  choiceSet = {
    {
      choiceID = 42,
      menuName = "menuName"
    },
    {
      choiceID = 43,
      menuName = "menuName"
    }
  }
}

local cics2Params = {
  interactionChoiceSetID = 500,
  choiceSet = {
    {
      choiceID = 44,
      menuName = "menuName"
    },
    {
      choiceID = 45,
      menuName = "unique"
    }
  }
}

local cics3Params = {
  interactionChoiceSetID = 501,
  choiceSet = {
    {
      choiceID = 46,
      menuName = "menuName"
    },
    {
      choiceID = 47,
      menuName = "unique"
    }
  }
}

local performInteractionParams = {
  initialText = "StartPerformInteraction",
  interactionMode = "MANUAL_ONLY",
  interactionChoiceSetIDList = { 500, 501 }
}

local performInteraction2Params = {
  initialText = "StartPerformInteraction",
  interactionMode = "MANUAL_ONLY",
  interactionChoiceSetIDList = { 499, 500, 501 }
}

--[[ Local Functions ]]
local function createInteractionChoiceSet(pParams)
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", pParams)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function performInteraction(pParams)
  local cid = common.getMobileSession():SendRPC("PerformInteraction", pParams)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction")
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

runner.Title("Test")
runner.Step("CreateInteractionChoiceSet1 with dupe menuNames", createInteractionChoiceSet, { cics1Params })
runner.Step("CreateInteractionChoiceSet2 with (menuName, unique)", createInteractionChoiceSet, { cics2Params })
runner.Step("CreateInteractionChoiceSet3 again with (menuName, unique)", createInteractionChoiceSet, { cics3Params })
runner.Step("PerformInteraction with choice set 2 and 3", performInteraction, { performInteractionParams })
runner.Step("PerformInteraction with all choice sets", performInteraction, { performInteraction2Params })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
