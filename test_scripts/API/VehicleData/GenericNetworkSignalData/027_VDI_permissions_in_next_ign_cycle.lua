---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying of the update for VehicleDataItems from PTU after already successful one

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VehicleData from VehicleDataItems are defined in parameters of functional group for application

-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. SubscribeVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.SubscribeVD with VD_name for RPC spec data and with VD_key for custom data to HMI
-- 3. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data to SDL
--   a. SDL processes successful response from HMI
--   b. SDL converts VD_keys to VD_names for mobile response
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app
-- 4. HMI sends OnVD notification with subscribed data
--   a. SDL resends the OnVD notification to mobile app
-- 5. GetVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.GetVD with VD_name for RPC spec data and with VD_key for custom data to HMI
-- 6. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data to SDL
--   a. SDL processes successful response from HMI
--   b. SDL converts VD_keys to VD_names for mobile response
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app
-- 7. UnsubscribeVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.UnsubscribeVD with VD_name for RPC spec data and with VD_key for custom data to HMI
-- 8. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data to SDL
--   a. SDL processes successful response from HMI
--   b. SDL converts VD_keys to VD_names for mobile response
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app
-- 9. HMI sends OnVD notification with subscribed data
--   a. SDL does not send the OnVD notification to mobile app
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

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
runner.Step("Ignition off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration after ign_off", common.registerAppWOPTU)
runner.Step("App activation after ign_off", common.activateApp)
for _, vehicleDataItem in pairs(common.VehicleDataItemsWithData) do
  if vehicleDataItem.name == "vin" then
    runner.Step("GetVehicleData " .. vehicleDataItem.name, common.GetVD,
      { appSessionId, vehicleDataItem.name })
  else
    runner.Step("SubscribeVehicleData " .. vehicleDataItem.name, common.VDsubscription,
      { appSessionId, vehicleDataItem.name, "SubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataItem.name, common.onVD,
      { appSessionId, vehicleDataItem.name })
    runner.Step("GetVehicleData " .. vehicleDataItem.name, common.GetVD,
      { appSessionId, vehicleDataItem.name })
    runner.Step("UnsubscribeVehicleData " .. vehicleDataItem.name, common.VDsubscription,
      { appSessionId, vehicleDataItem.name, "UnsubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataItem.name, common.onVD,
      { appSessionId, vehicleDataItem.name, common.VD.NOT_EXPECTED })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
