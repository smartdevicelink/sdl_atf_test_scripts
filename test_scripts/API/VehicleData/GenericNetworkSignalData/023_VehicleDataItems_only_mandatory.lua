---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing of the custom VD item only with mandatory parameters

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains the custom VD items in VehicleDataItems with only mandatory parameters( name, type, key , mandatory)
-- 4. Custom VD is allowed
-- 5. App is subscribed for custom VD

-- Sequence:
-- 1. HMI sends OnVD with custom VD with only mandatory child parameters
--   a. SDL resends OnVD notification to mobile app
-- 2. GetVD is requested for custom VD from mobile app
--   a. SDL sends VI.GetVehicleData request to HMI
-- 3. HMI responds with successful response to SDL
--   a. SDL processes successful response from HMI
--   b. SDL sends successful response to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
for vehicleDataKey, vehicleDataItem in pairs(common.customDataTypeSample) do
  if vehicleDataItem.name == "custom_vd_item1_integer" then
    for vehicleDataParam in pairs(common.customDataTypeSample[vehicleDataKey]) do
      if vehicleDataParam ~= "name" and
        vehicleDataParam ~= "type" and
        vehicleDataParam ~= "key" and
        vehicleDataParam ~= "mandatory" then
          common.customDataTypeSample[vehicleDataKey][vehicleDataParam] = nil
      end
    end
  end
end

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems, only mandatory in custom_vd_item1_integer", common.policyTableUpdateWithOnPermChange,
  { common.ptuFuncWithCustomData })

runner.Title("Test")
runner.Step("SubscribeVehicleData to custom_vd_item1_integer", common.VDsubscription,
  { appSessionId, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("OnVehicleData for custom_vd_item1_integer", common.onVD, { appSessionId, "custom_vd_item1_integer" })
runner.Step("GetVehicleData custom_vd_item1_integer", common.GetVD, { appSessionId, "custom_vd_item1_integer" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
