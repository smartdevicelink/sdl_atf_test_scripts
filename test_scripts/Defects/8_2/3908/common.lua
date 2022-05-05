---------------------------------------------------------------------------------------------------
-- Common module for tests of https://github.com/SmartDeviceLink/sdl_core/issues/3908 issue
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require('user_modules/sequences/actions')
local rc = require('user_modules/sequences/remote_control')
local json = require("modules/json")
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
actions.app.getParams().appHMIType = { "REMOTE_CONTROL" }

--[[ Module ]]
local m = { }

--[[ Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.start = actions.start
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.getHMIConnection = actions.getHMIConnection
m.policyTableUpdate = actions.policyTableUpdate
m.EMPTY_ARRAY = json.EMPTY_ARRAY
m.getParams = actions.app.getParams

--[[ Common Variables ]]
m.odometer1 = 15
m.odometer2 = 30

--[[ Common Functions ]]
function m.onVehicleDataPtuTrigger(pValue)
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { odometer = pValue })
  local policyMode = SDL.buildOptions.extendedPolicy
  if policyMode == "HTTP" then
    m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
      { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
    :Times(2)
  else
    m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
  end
end

function m.setInteriorVehicleDataRadio()
  local index = 1
  local appId = 1
  local radioData = rc.predefined.getModuleControlData("RADIO", index)
  rc.rc.rpcSuccess("RADIO", radioData.moduleId, appId, "SetInteriorVehicleData" )
end

function m.updFuncWrapper(pModuleType)
  local function updFunc(pTbl)
    local appPolicies = pTbl.policy_table.app_policies
    local index = actions.app.getParams().fullAppID
    appPolicies[index].groups = { "Base-4", "RemoteControl" }
    appPolicies[index].moduleType = pModuleType
    pTbl.policy_table.module_config.exchange_after_x_kilometers = 10
  end
  return updFunc
end

return m
