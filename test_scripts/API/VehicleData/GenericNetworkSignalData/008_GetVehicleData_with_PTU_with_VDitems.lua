---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: GetVD for RPC spec and custom data after PTU with VehicleDataItems

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VehicleData from VehicleDataItems are defined in parameters of functional group for application

-- Sequence:
-- 1. GetVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.GetVD with VD_name for RPC spec data and with VD_key for custom data to HMI
-- 2. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data to SDL
--   a. SDL processes successful response from HMI
--   b. SDL converts VD_keys to VD_names for mobile response
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app
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
for vehicleDataName in pairs(common.VehicleDataItemsWithData) do
  runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD,
    { appSessionId, vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
