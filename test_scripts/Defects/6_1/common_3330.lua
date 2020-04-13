---------------------------------------------------------------------------------------------------
-- common module for 3330 issue
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local utils = require('user_modules/utils')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Variables ]]
local m = {}
m.preconditions = commonRC.preconditions
m.start = commonRC.start
m.registerAppWOPTU = commonRC.registerAppWOPTU
m.activateApp = commonRC.activateApp
m.postconditions = commonRC.postconditions

--[[ Common Functions ]]
function m.rpcSuccessful(isIdParamDefined)
  local seatParams = utils.cloneTable(commonRC.getModuleControlData("SEAT"))
  if isIdParamDefined == false then seatParams.seatControlData.id = nil end

  local requestParams = utils.cloneTable(seatParams)
  requestParams.moduleId = nil

  local mobSession = commonRC.getMobileSession()
  local rpc = "SetInteriorVehicleData"
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc), { moduleData = requestParams })
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), { moduleData = requestParams })
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { moduleData = seatParams })
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", moduleData = seatParams })
end

function m.rpcUnsuccessful(isIdParamDefined)
  local seatParams = utils.cloneTable(commonRC.getModuleControlData("SEAT"))
  if isIdParamDefined == false then seatParams.seatControlData.id = nil end

  local requestParams = utils.cloneTable(seatParams)
  requestParams.moduleId = nil

  local mobSession = commonRC.getMobileSession()
  local rpc = "SetInteriorVehicleData"
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc), { moduleData = requestParams })
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc))
  :Times(0)

  mobSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

return m
