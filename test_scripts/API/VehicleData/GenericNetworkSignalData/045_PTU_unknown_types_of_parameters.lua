---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Description: Processing PTU with unknown types of custom VD parameters

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is started
-- 4. The update received from cloud contains the custom VD items with an unknown enum data type of parameter

-- Sequence:
-- 1. Mobile app requests RPC with RPC spec data
--   a. SDL processes the request successfully
-- 2. Mobile app requests RPC with custom data from PTU
--   a. SDL processes the request successfully, allowing arbitrary string values for the modified parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()
common.VehicleDataItemsWithData.custom_vd_item1_integer.value = "FUTURE_VALUE"

local appSessionId = 1
local customData, rpcSpecData = common.getCustomAndRpcSpecDataNames()

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("UpdateCustomDataTypeSample", common.updateCustomDataTypeSample,
  {"custom_vd_item1_integer", "type", "FutureType" } )
runner.Step("PTU with VehicleDataItems", common.policyTableUpdate,
  { common.ptuFuncWithCustomData })

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
  runner.Step("SubscribeVehicleData " .. vehicleDataItem, common.VDsubscription,
    { appSessionId, vehicleDataItem, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataItem, common.onVD,
    { appSessionId, vehicleDataItem })
  runner.Step("GetVehicleData " .. vehicleDataItem, common.GetVD,
    { appSessionId, vehicleDataItem })
  runner.Step("UnsubscribeVehicleData CUSTOM_DATA " .. vehicleDataItem, common.VDsubscription,
    { appSessionId, vehicleDataItem, "UnsubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataItem, common.onVD,
    { appSessionId, vehicleDataItem, common.VD.NOT_EXPECTED })
end

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

