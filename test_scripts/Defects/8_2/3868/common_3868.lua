---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")

--[[ Module ]]
local m = {}

--[[ Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.start = actions.start
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.getHMIAppId = actions.app.getHMIId
m.policyTableUpdate = actions.policyTableUpdate

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Variables ]]
m.tcs = {
  [01] = "WARNINGS",
  [02] = "TRUNCATED_DATA",
  [03] = "RETRY",
  [04] = "SAVED",
  [05] = "WRONG_LANGUAGE",
  [06] = "UNSUPPORTED_RESOURCE"
}

m.responsesStructures = {
  result = function(data, code) m.getHMIConnection():SendResponse(data.id, data.method, code, {}) end,
  error = function(data, code) m.getHMIConnection():SendError(data.id, data.method, code, "Error message") end
}

--[[ Local Functions ]]
local function getCreateWindowParam(windowID)
  local createWindowParam = {
    windowID = windowID,
    windowName = "Name_" .. windowID,
    type = "WIDGET"
  }
  return createWindowParam
end

--[[ Common Functions ]]
function m.ptUpdate(pTbl)
  pTbl.policy_table.app_policies[actions.getConfigAppParams().fullAppID].groups = { "Base-4", "WidgetSupport" }
end

function m.createWindow(pWindowID, response)
  local params = getCreateWindowParam(pWindowID)
  local cid = m.getMobileSession():SendRPC("CreateWindow", params)
  params.appID = m.getHMIAppId()
  m.getHMIConnection():ExpectRequest("UI.CreateWindow", params)
  :Do(function(_, data)
      response.structure(data, response.code)
    end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = response.code })
  m.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", windowID = params.windowID })
  m.getMobileSession():ExpectNotification("OnHashChange")
end

return m
