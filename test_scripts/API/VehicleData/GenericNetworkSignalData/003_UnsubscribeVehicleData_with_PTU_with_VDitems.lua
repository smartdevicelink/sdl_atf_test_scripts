---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Unsubscription for RPC spec and custom data after PTU with VehicleDataItems

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VehicleData from VehicleDataItems are defined in parameters of functional group for application

-- Sequence:
-- 1. UnsubscribeVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.UnsubscribeVD with VD_name for RPC spec data and with VD_key for custom data to HMI
-- 2. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data to SDL
--   a. SDL processes successful response from HMI
--   b. SDL converts VD_keys to VD_names for mobile response
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app
-- 3. HMI sends OnVD notification with subscribed data
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
-- removed because vin parameter is not applicable for SubscribeVehicleData
common.VehicleDataItemsWithData.vin = nil

local appSessionId = 1

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
for vehicleDataName in pairs(common.VehicleDataItemsWithData) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
