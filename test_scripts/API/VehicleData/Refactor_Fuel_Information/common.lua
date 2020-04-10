---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Variables ]]
local m = actions
m.Title = runner.Title
m.Step = runner.Step
m.start = actions.start
m.registerApp = actions.registerApp
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.policyTableUpdate = actions.policyTableUpdate
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.fail = actions.run.fail
m.cloneTable = utils.cloneTable

m.allVehicleData = {
  type = "GASOLINE",
  range = 5000,
  level = -6,
  levelState = "NORMAL",
  capacity = 0,
  capacityUnit = "LITERS"
}

m.subUnsubParams = {
  dataType = "VEHICLEDATA_FUELRANGE",
  resultCode = "SUCCESS"
}

m.respForDeprecatedParam = {
  fuelLevel = 106 ,
  fuelLevel_State = "NORMAL",
}

m.subVDdeprecatedParams = {
  fuelLevel = { dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "SUCCESS" },
  fuelLevel_State = { dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS" }
}

--[[ Functions ]]

--[[ @pTUpdateFunc: Policy Table Update with allowed "VehicleInfo-3" group for application
--! @parameters:
--! tbl - policy table
--! @return: none
--]]
function m.pTUpdateFunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "VehicleInfo-3"}
  tbl.policy_table.functional_groupings["VehicleInfo-3"].user_consent_prompt = nil
end

--[[ checkParam: Check the absence of unexpected params in GetVehicleData and OnVehicleData on the mobile app side
--! @parameters:
--! pData - parameters for mobile response/notification
--! pRPC - RPC for mobile request/notification
--! @return: true - in case response/notification does not contain unexpected params, otherwise - false
--]]
function m.checkParam(pData, pRPC)
  local count = 0
  for _ in pairs(pData.payload.fuelRange[1]) do
    count = count + 1
  end
  if count ~= 1 then
    return false, "Unexpected params are received in " .. pRPC
  else
    return true
  end
end

--[[ getVehicleData: Processing GetVehicleData RPC
--! @parameters:
--! pData - parameters for mobile response
--! pParam - parameters for GetVehicleData RPC
--! @return: none
--]]
function m.getVehicleData(pData, pParam)
  if not pParam then pParam = "fuelRange" end
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { [pParam] = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { [pParam] = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = pData })
    end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", [pParam] = pData })
end

--[[ subUnScribeVD: Processing SubscribeVehicleData and UnsubscribeVehicleData RPCs
--! @parameters:
--! pRPC - RPC for mobile request
--! pData - parameters for mobile response
--! pParam - parameters for SubscribeVehicleData and UnsubscribeVehicleData RPCs
--! @return: none
--]]
function m.subUnScribeVD(pRPC, pData, pParam)
  if not pParam then pParam = "fuelRange" end
  local cid = m.getMobileSession():SendRPC(pRPC, { [pParam] = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { [pParam] = true })
    :Do(function(_,data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = pData })
    end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", [pParam] = pData  })
end

--[[ sendOnVehicleData: Processing OnVehicleData RPC
--! @parameters:
--! pData - data for pParam
--! pExpTime - number of notifications
--! pParam - parameters for the notification
--! @return: none
--]]
function m.sendOnVehicleData(pData, pExpTime, pParam)
  if not pParam then pParam = "fuelRange" end
  if not pExpTime then pExpTime = 1 end

  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { [pParam] = pData })
  m.getMobileSession():ExpectNotification("OnVehicleData", { [pParam] = pData })
  :Times(pExpTime)
end

return m
