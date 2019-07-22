---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description:GetVehicleData for RPC spec VD data from preloaded file

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData are allowed by policies
-- 3. App is registered and activated
-- 4. PTU is not performed

-- Sequence:
-- 1. GetVD is requested from mobile app
--   a. SDL sends VI.GetVD with VD_name to HMI
-- 2. HMI responds with successful response with VD_name to SDL
--   a. SDL processes successful response from HMI
--   b. SDL sends successful response with received params to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appSessionId = 1

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration without PTU", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for vehicleDataName in pairs(common.VehicleDataItemsWithData) do
  runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD,
    { appSessionId, vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
