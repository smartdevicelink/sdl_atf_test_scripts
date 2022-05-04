---------------------------------------------------------------------------------------------------
-- Common module for tests of https://github.com/SmartDeviceLink/sdl_core/issues/3882 issue
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')

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
m.activateApp = actions.activateApp
m.getHMIConnection = actions.hmi.getConnection
m.getHMIId = actions.app.getHMIId
m.getPolicyAppId = actions.app.getPolicyAppId
m.getAppParams = actions.app.getParams
m.tableToString = utils.tableToString
m.isTableEqual = utils.isTableEqual

--[[ Common Variables ]]
m.hmiTypes = {
  [1] = "DEFAULT",
  [2] = "COMMUNICATION",
  [3] = "MEDIA",
  [4] = "MESSAGING",
  [5] = "NAVIGATION",
  [6] = "INFORMATION",
  [7] = "SOCIAL",
  [8] = "BACKGROUND_PROCESS",
  [9] = "TESTING",
  [10] = "SYSTEM",
  [11] = "PROJECTION",
  [12] = "REMOTE_CONTROL"
}
m.tcsActivation = {
  [1] = { name = "with app activation", isActive = true },
  [2] = { name = "without app activation", isActive = false }
}

--[[ Common Functions ]]
function m.ptu(pHMItype, pChangeRegistrationExtension, pUpdFuncWrapper)
  if pChangeRegistrationExtension then
    pChangeRegistrationExtension(pHMItype)
  else
    m.getHMIConnection():ExpectRequest("UI.ChangeRegistration", { appHMIType = pHMItype, appID = m.getHMIId() })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end

  if pUpdFuncWrapper then
    actions.policyTableUpdate(pUpdFuncWrapper(pHMItype))
  else
    local function updFunc(pTbl)
      pTbl.policy_table.app_policies[m.getPolicyAppId()].AppHMIType = pHMItype
    end
    actions.policyTableUpdate(updFunc)
  end
end

function m.appRegistration(pHMItype)
  m.getAppParams(1).appHMIType = pHMItype
  actions.registerApp()
end

function m.registerSecondAppWOptu(pHMItype)
  m.getAppParams(2).appHMIType = pHMItype
  actions.registerAppWOPTU(2)
end

function m.changeRegistration2apps(pHMItype)
  local expectedAppIds = { m.getHMIId(1), m.getHMIId(2) }
  local actualAppIds = {}
  m.getHMIConnection():ExpectRequest("UI.ChangeRegistration", { appHMIType = pHMItype })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(exp, data)
      table.insert(actualAppIds, data.params.appID)
      if exp.occurences == 2 then
        local result = m.isTableEqual(expectedAppIds, actualAppIds)
        if result == false then
          return result, "Expected table:\n" .. m.tableToString(expectedAppIds) .. "\n" ..
            "Actual table:\n" .. m.tableToString(actualAppIds)
        end
      end
      return true
    end)
  :Times(2)
end

return m
