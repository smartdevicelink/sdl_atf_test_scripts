---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL removes all VD items after PTU with empty vehicle_data

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed with VehicleDataItems in update file
-- 4. VehicleData from VehicleDataItems are defined in parameters of functional group for application
-- 5. PTU is triggered from HMI

-- Sequence:
-- 1. PTU is performed with empty vehicle_data structure in update file
-- 2. Mobile app requests RPC with RPC spec data
--   a. SDL processes the request successfully
-- 3. Mobile app requests RPC with custom data from first PTU
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

--[[ Local Functions ]]
local function ptuFuncWithVDI(pTbl)
  pTbl.policy_table.vehicle_data = { }
  pTbl.policy_table.vehicle_data.schema_items = common.customDataTypeSample
  pTbl.policy_table.vehicle_data.schema_version = "00.00.02"
  pTbl.policy_table.functional_groupings.NewGroupWithAllData = common.cloneTable(
  pTbl.policy_table.functional_groupings["Emergency-1"])

  local rpcsGroupWithAllVehicleData = pTbl.policy_table.functional_groupings.NewGroupWithAllData.rpcs
  local allVehicleData = common.getAllVehicleData()
  rpcsGroupWithAllVehicleData.GetVehicleData.parameters = allVehicleData
  rpcsGroupWithAllVehicleData.OnVehicleData.parameters = allVehicleData
  rpcsGroupWithAllVehicleData.SubscribeVehicleData.parameters = allVehicleData
  rpcsGroupWithAllVehicleData.UnsubscribeVehicleData.parameters = allVehicleData

  pTbl.policy_table.app_policies[common.getPolicyAppId(1)].groups = {
    "Base-4", "NewGroupWithAllData"
  }
end

local function ptuFunc(pTbl)
  ptuFuncWithVDI(pTbl)
  pTbl.policy_table.vehicle_data = common.EMPTY_OBJECT
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { ptuFuncWithVDI })
runner.Step("PTU with empty vehicle_data", common.ptuWithOnPolicyUpdateFromHMI, { ptuFunc, rpcSpecData })

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
  runner.Step("OnVehicleData " .. vehicleDataItem, common.onVD,
    { appSessionId, vehicleDataItem, common.VD.NOT_EXPECTED })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
