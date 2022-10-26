---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Module ]]
local m = {}

--[[ Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.start = actions.start
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.getHMIConnection = actions.getHMIConnection

--[[ Common Functions ]]
function m.getVehicleData(pParams)
  local cid = actions.getMobileSession():SendRPC("GetVehicleData", pParams.request)
  actions.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", pParams.request)
  :Do(function(_, data)
      pParams.respFunc(data)
    end)
  actions.getMobileSession():ExpectResponse(cid, pParams.respExp)
end

function m.policyTableUpdate()
  local function updFunc(tbl)
      tbl.policy_table.functional_groupings["Location-1"].user_consent_prompt = nil
      tbl.policy_table.app_policies[actions.app.getParams().fullAppID].groups = {"Base-4", "Location-1"}
  end
  actions.policyTableUpdate(updFunc)
end

return m
