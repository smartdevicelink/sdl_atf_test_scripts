---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2400
--
-- Description:
-- SDL behavior in case mobile app sends reques with at least one choiseSet without parameter and at least one choiseSet with at MANUAL_ONLY mode 
-- Steps to reproduce:
-- 1) Mobile app sends PerformInteraction with interactionMode: MANUAL_ONLY and one or more (choiseSet_created_ without and one
--    or more choiseSet_created with) parameters.
-- Expected:
-- 1) Send VR.PerformInteraction with all prompts (helpPrompt, timeoutPrompt, initialPrompt) to HMI
-- 2) Send UI.PerformInteraction with all requested choiseSets to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local variables ]]
local hmiParams = {
    helpPrompt = { type = "TEXT", text = "helpPrompt" },
    initialPrompt = { type = "TEXT", text = "initialPrompt" },
    timeoutPrompt = { type = "TEXT", text = "timeoutPrompt" }
}

local params = {
    initialText = "StartPerformInteraction",
    interactionMode = "MANUAL_ONLY",
    interactionChoiceSetIDList = { 100 },
    interactionChoiceSetIDList = { 110 }
}

-- [[ Local Functions ]]
local function createInteractionChoiceSetVR()
    local choiceParams = {
        interactionChoiceSetID = 100,
        choiceSet = {
          {
            choiceID = 111,
            menuName = "Choice111",
            vrCommands = { "Choice111" }
          }
        } 
    }
    local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", choiceParams)
    common.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end 

local function createInteractionChoiceSetWithoutVR()
    local choiceParams = {
        interactionChoiceSetID = 110,
        choiceSet = {
          {
            choiceID = 112,
            menuName = "Choice112"
          }
        } 
    }
    local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", choiceParams)
    common.getHMIConnection():ExpectRequest("VR.PerformInteraction")
    :Times(0)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end 

local function sendPerformInteraction()
    local cid = common.getMobileSession():SendRPC("PerformInteraction", params)
    common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
        helpPrompt = hmiParams.helpPrompt,
        initialPrompt = hmiParams.initialPrompt,
        timeoutPrompt = hmiParams.timeoutPrompt
    })        
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Create InteractionChoiceSetVR", createInteractionChoiceSetVR)
runner.Step("Create InteractionChoiceSetWithoutVR", createInteractionChoiceSetWithoutVR)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Send PerformInteraction ", sendPerformInteraction)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
