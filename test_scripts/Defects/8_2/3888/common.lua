---------------------------------------------------------------------------------------------------
-- Common module for tests of https://github.com/smartDeviceLink/sdl_core/issues/3888
---------------------------------------------------------------------------------------------------
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local color = require("user_modules/consts").color
local SDL = require('SDL')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Module ]]
local m = { }

--[[ Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.start = actions.start
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.spairs = utils.spairs
m.connectMobile = actions.mobile.connect

--[[ Local Variables ]]
local addSubMenuParams = {
  menuID = 1000,
  position = 500,
  menuName ="Sub Menu"
}

--[[ Common Variables ]]
m.testCases = {
  with_vr_command = {
    parameters = {
      interactionChoiceSetID = 1001,
      choiceSet = {
        {
          choiceID = 1001,
          menuName ="Choice1001",
          vrCommands = {
            "Choice1001"
          }
        }
      }
    },
    vrCommandTimes = 1,
    vrAddCommandRequest = {
      cmdID = 1001,
      type = "Choice",
      vrCommands = {
        "Choice1001"
      }
    }
  },
  without_vr_command = {
    parameters = {
      interactionChoiceSetID = 1002,
      choiceSet = {
        {
          choiceID = 1002,
          menuName ="Choice1002"
        }
      }
    },
    vrCommandTimes = 0
  }
}
m.hashID = 0
m.resumeFailedResult = "RESUME_FAILED"

--[[ Common Function ]]
function m.createInteractionChoiceSet(pParams)
  local cid = actions.getMobileSession():SendRPC("CreateInteractionChoiceSet", pParams.parameters)
  actions.getHMIConnection():ExpectRequest("VR.AddCommand", pParams.vrAddCommandRequest or {})
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_, data)
      if data.params.grammarID ~= nil then
        return true
      else
        return false, "grammarID should not be empty"
      end
    end)
  :Times(pParams.vrCommandTimes)
  actions.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  actions.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashID = data.payload.hashID
    end)
end

function m.unexpectedDisconnect()
  actions.mobile.disconnect()
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = actions.getHMIAppId(), unexpectedDisconnect = true })
end

function m.ignitionOff()
  local isOnSDLCloseSent = false
  actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
        { reason = "IGNITION_OFF" })
      actions.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          isOnSDLCloseSent = true
          SDL.DeleteFile()
        end)
    end)
  utils.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then utils.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    actions.mobile.deleteSession()
    StopSDL()
  end)
end

function m.raiWithResumption(pParams, additionalExpectations, raiResult)
  local mobSession = actions.getMobileSession()
  mobSession:StartService(7)
  :Do(function()
      local params = utils.cloneTable(actions.getConfigAppParams())
      params.hashID = m.hashID
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
        application = { appName = params.appName } })
      mobSession:ExpectResponse(corId, { success = true, resultCode = raiResult or "SUCCESS" })
    end)

  actions.getHMIConnection():ExpectRequest("VR.AddCommand", pParams.vrAddCommandRequest or {})
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_, data)
      if data.params.grammarID ~= nil then
        return true
      else
        return false, "grammarID should not be empty"
      end
    end)
  :Times(pParams.vrCommandTimes)

  if additionalExpectations then
    local cmdId
    if pParams.vrAddCommandRequest then cmdId = pParams.vrAddCommandRequest.cmdID end
    additionalExpectations(pParams.vrCommandTimes, cmdId)
  end

  utils.wait(1000)
end

function m.deleteInteractionChoiceSet(pChoiceId, pTimes)
  local cid = actions.getMobileSession():SendRPC("DeleteInteractionChoiceSet", { interactionChoiceSetID = pChoiceId })
  actions.getHMIConnection():ExpectRequest("VR.DeleteCommand", { cmdID = pChoiceId })
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(pTimes)
  actions.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  actions.getMobileSession():ExpectNotification("OnHashChange")
end

function m.addSubMenu()
  local cid = actions.getMobileSession():SendRPC("AddSubMenu", addSubMenuParams)
  actions.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  actions.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  actions.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashID = data.payload.hashID
    end)
end

function m.additionalResumptionContions(pTimes, pCmdId)
  actions.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      actions.getHMIConnection():SendError(data.id, data.method, "REJECTED", "Error response")
    end)
  actions.getHMIConnection():ExpectRequest("VR.DeleteCommand", { cmdID = pCmdId })
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(pTimes)
end

return m
