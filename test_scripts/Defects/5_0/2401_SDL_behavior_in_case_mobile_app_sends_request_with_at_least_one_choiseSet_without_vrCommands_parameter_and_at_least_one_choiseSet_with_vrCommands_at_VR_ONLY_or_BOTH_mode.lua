---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2401
--
-- Description:
-- SDL behavior in case mobile app sends request with at least one choiseSet without parameter and at least one choiseSet with at VR_ONLY or BOTH mode 
-- Steps to reproduce:
-- 1) Mobile app sends PerformInteraction with interactionMode:  VR_ONLY or BOTH and one or more (choiseSet_created_ without 
--    and one or more choiseSet_created with) parameters.
-- Expected SDL must:
-- 1) Respond INVALID_DATA to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local paramsVrOnly = {
    initialText = "StartPerformInteraction1",
    interactionMode = "VR_ONLY",
    interactionChoiceSetIDList = { 10 },
    interactionChoiceSetIDList = { 11 }
}

local paramsBoth = {
    initialText = "StartPerformInteraction2",
    interactionMode = "BOTH",
    interactionChoiceSetIDList = { 10 },
    interactionChoiceSetIDList = { 11 }
}

-- [[ Local Functions ]]
local function createInteractionChoiceSetVR()
    local choiceParams = {
        interactionChoiceSetID = 11,
        choiceSet = {
          {
            choiceID = 11,
            menuName = "Choice11",
            vrCommands = { "Choice11" }
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
        interactionChoiceSetID = 10,
        choiceSet = {
          {
            choiceID = 10,
            menuName = "Choice10"
          }
        } 
    }
    local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", choiceParams)
    common.getHMIConnection():ExpectRequest("VR.PerformInteraction")
    :Times(0)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end 

local function sendPerformInteractionVR()
    local cid = common.getMobileSession():SendRPC("PerformInteraction", paramsVrOnly)
    common.getHMIConnection():ExpectRequest("VR.PerformInteraction")
    :Times(0)        
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

local function sendPerformInteractionBOTH()
    local cid = common.getMobileSession():SendRPC("PerformInteraction", paramsBoth)
    common.getHMIConnection():ExpectRequest("VR.PerformInteraction")
    :Times(0)        
    common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
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
runner.Step("Send PerformInteraction VR_ONLY mode", sendPerformInteractionVR)
runner.Step("Send PerformInteraction BOTH mode", sendPerformInteractionBOTH)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
