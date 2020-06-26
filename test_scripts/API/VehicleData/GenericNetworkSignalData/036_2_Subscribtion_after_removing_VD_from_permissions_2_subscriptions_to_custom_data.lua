---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing VD subscription in case when app is subscribed to custom data_1, data_2
-- and after PTU is performed with removing of data_1

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group
-- 6. App is subscribed to custom data_1
-- 7. App is subscribed to custom data_2

-- Sequence:
-- 1. PTU is triggered and performed with removed data_1 from VehicleDataItems
--   a. SDL sends VI.Unsubscribe(data_1) to HMI
-- 2. HMI sends OnVD(data_1) notification
--   a. SDL does not resend the OnVD notification to mobile app
-- 3. HMI sends OnVD(data_2) notification
--   a. SDL resends the OnVD notification to mobile app
-- 4. Mobile app requests SubscribeVehicleData(data_1)
--   a. SDL rejects requests with INVALID_DATA resultCode
-- 5. Ignition off is performed
-- 6. Ignition on is performed
-- 7. Mobile app is registered and resumes the subscription for data_2
-- 8. HMI sends OnVD(data_1) notification
--   a. SDL does not resend the OnVD notification to mobile app
-- 9. HMI sends OnVD(data_2) notification
--   a. SDL resends the OnVD notification to mobile app
-- 10. Mobile app requests SubscribeVehicleData(data_1)
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
local itemToRemove = "custom_vd_item1_integer"
local customVD = "custom_vd_item2_float"

--[[ Local Functions ]]
local function ptuFunc(pTbl)
  common.ptuFuncWithCustomData(pTbl)
  for key, item in pairs(pTbl.policy_table.vehicle_data.schema_items) do
    if item.name == itemToRemove then
      table.remove(pTbl.policy_table.vehicle_data.schema_items, key)
    end
  end
end

local function getParamsListForOnPermChange()
  local out = common.getAllVehicleData()
  for k,v in pairs(out) do
    if v == itemToRemove then
      table.remove(out, k)
    end
  end
  return out
end

local function expectFunc()
  local itemToRemoveKey =  common.VehicleDataItemsWithData[itemToRemove].key
  local expectedRequest = { [itemToRemoveKey] = true }
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {[itemToRemoveKey] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }})
  end)
  :ValidIf(function(_, data)
    return common.validation(data.params, expectedRequest, "VehicleInfo.UnsubscribeVehicleData")
  end)
end

local function registerAppWithResumption()
  local itemKey =  common.VehicleDataItemsWithData[customVD].key
  local expectedRequest = { [itemKey] = true }
  common.getConfigAppParams(appSessionId).hashID = common.hashId
  common.registerAppWOPTU()

  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {[itemKey] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }})
  end)
  :ValidIf(function(_, data)
    return common.validation(data.params, expectedRequest, "VehicleInfo.UnsubscribeVehicleData")
  end)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
runner.Step("SubscribeVehicleData " .. itemToRemove, common.VDsubscription,
  { appSessionId, itemToRemove, "SubscribeVehicleData" })
runner.Step("SubscribeVehicleData " .. customVD, common.VDsubscription,
  { appSessionId, customVD, "SubscribeVehicleData" })
runner.Step("OnVehicleData " .. customVD, common.onVD,
  { appSessionId, customVD })
runner.Step("OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId, itemToRemove })
runner.Step("PTU with removing " .. itemToRemove .. " from VehicleDataItems", common.ptuWithOnPolicyUpdateFromHMI,
  { ptuFunc, getParamsListForOnPermChange(), expectFunc })
runner.Step("OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId, itemToRemove, common.VD.NOT_EXPECTED })
runner.Step("OnVehicleData " .. customVD, common.onVD,
  { appSessionId, customVD })
runner.Step("SubscribeVehicleData " .. itemToRemove .. " after VD was removed", common.errorRPCprocessing,
  { appSessionId, itemToRemove, "SubscribeVehicleData", "INVALID_DATA" })

runner.Step("Ignition off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration after ign_off", registerAppWithResumption)
runner.Step("App activation after ign_off", common.activateApp)

runner.Step("OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId, itemToRemove, common.VD.NOT_EXPECTED })
runner.Step("OnVehicleData " .. customVD, common.onVD,
  { appSessionId, customVD })
runner.Step("SubscribeVehicleData " .. itemToRemove .. " after VD was removed", common.errorRPCprocessing,
  { appSessionId, itemToRemove, "SubscribeVehicleData", "INVALID_DATA" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
