---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing VD subscription in case when app is subscribed to custom data_1 and after PTU is performed
-- with removing of data_1

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group
-- 6. App is subscribed to custom data_1

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
local itemToRemove = "custom_vd_item1_integer"

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
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", { [itemToRemoveKey] = true })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {[itemToRemoveKey] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }})
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
runner.Step("OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId, itemToRemove })
runner.Step("PTU with removing " .. itemToRemove .. " from VehicleDataItems", common.ptuWithOnPolicyUpdateFromHMI,
  { ptuFunc, getParamsListForOnPermChange(), expectFunc })
runner.Step("OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId, itemToRemove, common.VD.NOT_EXPECTED })
runner.Step("SubscribeVehicleData " .. itemToRemove .. " after VD was removed", common.errorRPCprocessing,
  { appSessionId, itemToRemove, "SubscribeVehicleData", "INVALID_DATA" })

runner.Step("Ignition off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration after ign_off", common.registerAppWOPTU)
runner.Step("App activation after ign_off", common.activateApp)

runner.Step("OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId, itemToRemove, common.VD.NOT_EXPECTED })
runner.Step("SubscribeVehicleData " .. itemToRemove .. " after VD was removed", common.errorRPCprocessing,
  { appSessionId, itemToRemove, "SubscribeVehicleData", "INVALID_DATA" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
