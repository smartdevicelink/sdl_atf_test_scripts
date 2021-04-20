---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing PTU with white spaces and invalid characters in vehicle_data items

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is started
-- 4. The update received from cloud contains name or keys with white spaces, spec characters, empty values

-- Sequence:
-- 1. Update is considered as invalid and PTU status is still UPDATE_NEEDED
-- 2. Mobile app requests RPC with RPC spec data
--   a. SDL processes the request successfully
-- 3 Mobile app requests RPC with custom data from PTU
--   a. SDL rejects requests with INVALID_DATA resultCode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1
local customData, rpcSpecData = common.getCustomAndRpcSpecDataNames()

local updateFunctions = {
  itemForFirstUpdate = {
    specialCharactersName = function(pTbl)
      common.ptuFuncWithCustomData(pTbl)
      pTbl.policy_table.vehicle_data.schema_items[1].name = "NameWith!@#$%%^^&**"
    end
  },
  itemsForNextUpdates = {
    spaceName = function(pTbl)
      common.ptuFuncWithCustomData(pTbl)
      pTbl.policy_table.vehicle_data.schema_items[1].name = "Some name"
    end,
    onlySpaceName = function(pTbl)
      common.ptuFuncWithCustomData(pTbl)
      pTbl.policy_table.vehicle_data.schema_items[1].name = "     "
    end,
    emptyName = function(pTbl)
     common.ptuFuncWithCustomData(pTbl)
     pTbl.policy_table.vehicle_data.schema_items[1].name = ""
   end,
    specialCharactersKey = function(pTbl)
     common.ptuFuncWithCustomData(pTbl)
     pTbl.policy_table.vehicle_data.schema_items[1].key = "NameWith!@#$%%^^&**"
   end,
    spaceKey = function(pTbl)
     common.ptuFuncWithCustomData(pTbl)
     pTbl.policy_table.vehicle_data.schema_items[1].key = "Some name"
   end,
    onlySpaceKey = function(pTbl)
     common.ptuFuncWithCustomData(pTbl)
     pTbl.policy_table.vehicle_data.schema_items[1].key = "     "
   end,
    emptyKey = function(pTbl)
     common.ptuFuncWithCustomData(pTbl)
     pTbl.policy_table.vehicle_data.schema_items[1].key = ""
   end
  }
}

--[[ Local Functions ]]
local function ExpNotificationFunc()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" })
  :Times(2)
end

local function policyTableUpdateWithoutOnPermChange(pPTUpdateFunc, pExpFunc)
  pExpFunc()
  common.isPTUStarted()
  :Do(function()
    common.policyTableUpdate(pPTUpdateFunc, function() end)
  end)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :Times(0)
  common.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems specialCharactersName", common.policyTableUpdateWithoutOnPermChange,
  { updateFunctions.itemForFirstUpdate.specialCharactersName, common.expUpdateNeeded })
for  key, value in pairs(updateFunctions.itemsForNextUpdates) do
  runner.Step("PTU with VehicleDataItems " .. key, policyTableUpdateWithoutOnPermChange,
    { value, ExpNotificationFunc })
end

runner.Title("Test")
for _, vehicleDataItem in pairs(rpcSpecData) do
  if vehicleDataItem == "vin" then
    runner.Step("GetVehicleData " .. vehicleDataItem, common.GetVD,
      { appSessionId, vehicleDataItem })
  else
    runner.Step("SubscribeVehicleData " .. vehicleDataItem, common.VDsubscription,
      { appSessionId, vehicleDataItem, "SubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataItem, common.onVD,
      { appSessionId, vehicleDataItem })
    runner.Step("GetVehicleData " .. vehicleDataItem, common.GetVD,
      { appSessionId, vehicleDataItem })
    runner.Step("UnsubscribeVehicleData " .. vehicleDataItem, common.VDsubscription,
      { appSessionId, vehicleDataItem, "UnsubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataItem, common.onVD,
      { appSessionId, vehicleDataItem, common.VD.NOT_EXPECTED })
  end
end
for _, vehicleDataItem in pairs(customData) do
  runner.Step("SubscribeVehicleData INVALID_DATA " .. vehicleDataItem, common.errorRPCprocessing,
    { appSessionId, vehicleDataItem, "SubscribeVehicleData", "INVALID_DATA" })
  runner.Step("OnVehicleData " .. vehicleDataItem, common.onVD,
    { appSessionId, vehicleDataItem, common.VD.NOT_EXPECTED })
  runner.Step("GetVehicleData INVALID_DATA " .. vehicleDataItem, common.errorRPCprocessing,
    { appSessionId, vehicleDataItem, "GetVehicleData", "INVALID_DATA" })
  runner.Step("UnsubscribeVehicleData INVALID_DATA " .. vehicleDataItem, common.errorRPCprocessing,
    { appSessionId, vehicleDataItem, "UnsubscribeVehicleData", "INVALID_DATA" })
end

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

