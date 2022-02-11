---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1883
---------------------------------------------------------------------------------------------------
-- Description: Check SDL rejects PerfromInteraction request if it's being sent during deleting of InteractionChoiceSet
--  in case deleting starts after successful resumption
---------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
-- In case:
-- 1. App is created InteractionChoiseSet(choiceSetID_1)
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App re-registered with actual hashId
-- 4. App sends DeleteInteractionChoiceSet(choiceSetID_1) request
-- SDL does:
-- - transfer request to HMI
-- 5. App sends PerformInteraction(choiceSetID_1) request
-- SDL does:
-- - not transfer request to HMI
-- - respond with REJECTED to the App
-- 6. HMI responds to DeleteInteractionChoiceSet
-- SDL does:
-- - respond DeleteInteractionChoiceSet(SUCCESS) to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestVrAddCommand = {
  cmdID = 111,
  type = "Choice",
  vrCommands = { "Choice111" }
}

local requestChoiceParams = {
  interactionChoiceSetID = 1,
  choiceSet = {
    {
      choiceID = 111,
      menuName = "Choice111",
      vrCommands = { "Choice111" }
    }
  }
}

local deleteChoiceSetID = {
  interactionChoiceSetID = requestChoiceParams.interactionChoiceSetID
}

local deleteResponseVrParams = {
  cmdID = requestChoiceParams.choiceID,
  type = "Choice"
}

local performParams = {
  initialText = "TextInitial",
  interactionMode = "MANUAL_ONLY",
  interactionChoiceSetIDList = { requestChoiceParams.interactionChoiceSetID },
  initialPrompt = {
    { type = "TEXT", text = "pathToFile1" }
  }
}

local hashId = ""

--[[ Local Functions ]]
local function createInteractionChoiceSet(pChoiceParams)
  local cid = common.mobile.getSession():SendRPC("CreateInteractionChoiceSet", pChoiceParams)

  common.hmi.getConnection():ExpectRequest("VR.AddCommand", requestVrAddCommand)
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.mobile.getSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.mobile.getSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
end

local function sendPerformInteraction_REJECTED()
  local cid = common.mobile.getSession():SendRPC("PerformInteraction", performParams)
  common.mobile.getSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
end

local function deleteInteractionChoiceSet(pDeleteChoiceParams, pDeleteVrCommandParams)
  local cid = common.mobile.getSession():SendRPC("DeleteInteractionChoiceSet", pDeleteChoiceParams)
  common.hmi.getConnection():ExpectRequest("VR.DeleteCommand", pDeleteVrCommandParams)
  :Do(function(_, data)
      sendPerformInteraction_REJECTED()
      local function deleteCommandResp()
        common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      common.run.runAfter(deleteCommandResp, 1000)
    end)
  common.mobile.getSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function reRegisterApp()
  common.app.getParams().hashID = hashId
  common.app.registerNoPTU()
  common.getHMIConnection():ExpectRequest("VR.AddCommand", requestVrAddCommand)
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(common.mobile.getAppsCount())
  common.mobile.disconnect()
  common.run.wait(1000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Create InteractionChoiceSet", createInteractionChoiceSet, { requestChoiceParams })
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Connect mobile", common.mobile.connect)
runner.Step("Re-register App", reRegisterApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Perform choiceSetID_1 during deleting choiceSetID_1", deleteInteractionChoiceSet,
  { deleteChoiceSetID, deleteResponseVrParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
