---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local runner = require('user_modules/script_runner')
local hmi_values = require("user_modules/hmi_values")
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local m = {}

--[[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.startOrigin = actions.start
m.postconditions = actions.postconditions
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.registerAppWOPTU = actions.app.registerNoPTU
m.activateApp = actions.app.activate
m.getMobileSession = actions.mobile.getSession
m.getHMIConnection = actions.hmi.getConnection
m.getConfigAppParams = actions.getConfigAppParams
m.json = utils.json
m.cloneTable = utils.cloneTable
m.getAppEventName = commonRC.getAppEventName
m.getAppRequestParams = commonRC.getAppRequestParams

--[[ Common Variables ]]
m.hmiExpectResponse = {
  errorCodeWithAvailable = true,
  errorWithoutAvailable = false
}

--[[ Common Functions ]]
function m.updatePreloadedPT()
  local pt = m.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = m.json.null
  pt.policy_table.app_policies[m.getConfigAppParams().fullAppID] = m.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[m.getConfigAppParams().fullAppID].moduleType = { "CLIMATE" }
  pt.policy_table.app_policies[m.getConfigAppParams().fullAppID].groups =
    { "Base-4", "SendLocation", "RemoteControl", "Location-1" }
  m.setPreloadedPT(pt)
end

function m.preconditions()
  actions.preconditions()
  m.updatePreloadedPT()
end

function m.start(pInterface, pHmiResponse)
  local function getHMIValues()
    local params = hmi_values.getDefaultHMITable()
    params[pInterface] = nil
    return params
  end
  m.startOrigin(getHMIValues())
  m.getHMIConnection():ExpectRequest(pInterface .. ".IsReady")
  :Do(function(_, data)
    if pHmiResponse == true then
      m.getHMIConnection():SendResponse(data.id, data.method, "REJECTED", { available = true })
    else
      m.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", "Error code")
    end
  end)
end

return m
