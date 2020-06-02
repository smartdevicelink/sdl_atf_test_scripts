---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local json = require("modules/json")
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
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.getConfigAppParams = actions.getConfigAppParams
m.json = utils.json
m.cloneTable = utils.cloneTable
m.getAppEventName = commonRC.getAppEventName
m.getAppRequestParams = commonRC.getAppRequestParams

--[[ Common Functions ]]
function m.updatePreloadedPT()
  local pt = m.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pt.policy_table.app_policies[m.getConfigAppParams(1).fullAppID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[m.getConfigAppParams(1).fullAppID].moduleType = { "CLIMATE" }
  pt.policy_table.app_policies[m.getConfigAppParams(1).fullAppID].groups =
    { "Base-4", "SendLocation", "RemoteControl", "Location-1" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  m.setPreloadedPT(pt)
end

function m.preconditions()
  actions.preconditions()
  m.updatePreloadedPT()
end

m.hmiExpectResponse = {
  errorCodeWithAvailable = true,
  errorWithoutAvailable = false
}

function m.start (pInterface, pHmiResponse)
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
