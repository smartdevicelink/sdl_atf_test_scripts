---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Unsubscription for RPC spec VD from preloaded file

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData are allowed by policies
-- 3. App is registered and activated
-- 4. PTU is not performed
-- 5. App is subscribed to VD

-- Sequence:
-- 1. UnsubscribeVD is requested from mobile app
--   a. SDL sends VI.UnsubscribeVD with VD_name to HMI
-- 2. HMI responds with successful response with VD_name to SDL
--   a. SDL processes successful response from HMI
--   b. SDL sends successful response with received params to mobile app
-- 3. HMI sends OnVD notification with subscribed data in VD_name
--   a. SDL does not send the OnVD notification wtih received data to mobile app
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
  runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)