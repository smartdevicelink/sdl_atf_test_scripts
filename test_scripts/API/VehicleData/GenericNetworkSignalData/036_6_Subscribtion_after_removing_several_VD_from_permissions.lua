---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing VD subscription in case when app is subscribed to custom data_1, data_2 and after PTU is performed
-- with removing of data_1, data_2

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group
-- 6. App is subscribed to custom data_1. data_2

-- Sequence:
-- 1. PTU is triggered and performed with removed data_1 from VehicleDataItems
--   a. SDL sends VI.Unsubscribe(data_1) to HMI
-- 2. HMI sends OnVD(data_1) notification
--   a. SDL does not resend the OnVD notification to mobile app
-- 3. Mobile app requests SubscribeVehicleData(data_1)
--   a. SDL rejects requests with INVALID_DATA resultCode
-- 4. Ignition off is performed
-- 5. Ignition on is performed
-- 6.  Mobile app requests SubscribeVehicleData(data_1)
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
local itemsToRemove = { "custom_vd_item1_integer", "custom_vd_item11_struct" }

--[[ Local Functions ]]
local function ptuFunc(pTbl)
  common.ptuFuncWithCustomData(pTbl)
  for _, itemName in pairs(itemsToRemove) do
    for key, item in pairs(pTbl.policy_table.vehicle_data.schema_items) do
      if item.name == itemName then
        table.remove(pTbl.policy_table.vehicle_data.schema_items, key)
      end
    end
  end
end

local function getParamsListForOnPermChange()
  local out = common.getAllVehicleData()
  for _, itemName in pairs(itemsToRemove) do
    for k,v in pairs(out) do
      if v == itemName then
        table.remove(out, k)
      end
    end
  end
  return out
end

local function expectFunc()
  local itemToRemoveKey1 = common.VehicleDataItemsWithData[itemsToRemove[1]].key
  local itemToRemoveKey2 = common.VehicleDataItemsWithData[itemsToRemove[2]].key
  local expectedRequest = { [itemToRemoveKey1] = true, [itemToRemoveKey2] = true }
  local responseStruct = { dataType = common.CUSTOM_DATA_TYPE, resultCode = "SUCCESS" }
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", expectedRequest)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
      [itemToRemoveKey1] = responseStruct,
      [itemToRemoveKey2] = responseStruct
    })
  end)
end

local function registerAppWithResumption()
  common.getConfigAppParams(appSessionId).hashID = common.hashId
  common.registerAppWOPTU(appSessionId)

  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Times(0)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
for _, itemName in pairs(itemsToRemove) do
  runner.Step("SubscribeVehicleData " .. itemName, common.VDsubscription,
    { appSessionId, itemName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. itemName, common.onVD,
    { appSessionId, itemName, common.VD.EXPECTED })
end
runner.Step("PTU with removing custom data from VehicleDataItems", common.ptuWithOnPolicyUpdateFromHMI,
  { ptuFunc, getParamsListForOnPermChange(), expectFunc })
for _, itemName in pairs(itemsToRemove) do
  runner.Step("OnVehicleData " .. itemName, common.onVD,
    { appSessionId, itemName, common.VD.NOT_EXPECTED })
  runner.Step("SubscribeVehicleData " .. itemName .. " after VD was removed", common.errorRPCprocessing,
    { appSessionId, itemName, "SubscribeVehicleData", "INVALID_DATA" })
end

runner.Step("Ignition off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration after ign_off", registerAppWithResumption)
runner.Step("App activation after ign_off", common.activateApp)

for _, itemName in pairs(itemsToRemove) do
  runner.Step("OnVehicleData " .. itemName, common.onVD,
    { appSessionId, itemName, common.VD.NOT_EXPECTED })
  runner.Step("SubscribeVehicleData " .. itemName .. " after VD was removed", common.errorRPCprocessing,
    { appSessionId, itemName, "SubscribeVehicleData", "INVALID_DATA" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
