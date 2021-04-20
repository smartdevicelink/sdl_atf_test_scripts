---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing PTU with fake item in parameters for RPCs

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is started
-- 4. The update received from cloud only with fake item in parameters for RPCs

-- Sequence:
-- 1. Update is performed successfully
-- 2. SDL sends OnPermissionChange notification without fake parameter
-- 3. Mobile app requests RPC with RPC spec data or custom data
--   a. SDL processes the request successfully
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

--[[ Local Functions ]]
local function ptuFunc(pTbl)
  common.ptuFuncWithCustomData(pTbl)
  table.insert(pTbl.policy_table.functional_groupings.GroupWithAllVehicleData.rpcs.GetVehicleData.parameters,
    "fake_item")
  table.insert(pTbl.policy_table.functional_groupings.GroupWithAllRpcSpecVehicleData.rpcs.GetVehicleData.parameters,
    "fake_item")
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { ptuFunc })

runner.Title("Test")
for _, vehicleDataItem in pairs(common.getAllVehicleData()) do
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

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
