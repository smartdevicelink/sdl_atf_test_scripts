---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing of RPC spec VD in case sdl_preloaded_pt file does not contain vehicle_data
--   and endpoint_properties section

-- Precondition:
-- 1. Preloaded file does not contain vehicle_data and endpoint_properties
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains VehicleDataItems with custom VD items
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VehicleData from VehicleDataItems are defined in parameters of functional group for application

-- Sequence:
-- 1. SubscribeVD/UnsubscribeVD/GetVD is requested from mobile app with VD from API
--   a. SDL sends request with VD to HMI
-- 2. HMI responds with successful response to SDL
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
local _, rpcSpecDataNames = common.getCustomAndRpcSpecDataNames()

--[[ Local Functions ]]
local function updatePreloadedPTWithoutVD()
  local preloadedTable, preloadedFile = common.getPreloadedFileAndContent()
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = common.null
  preloadedTable.policy_table.vehicle_data = nil
  preloadedTable.policy_table.module_config.endpoint_properties = nil
  common.tableToJsonFile(preloadedTable, preloadedFile)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Remove vehicle_data from preloaded", updatePreloadedPTWithoutVD)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for _, vehicleDataItem in pairs(rpcSpecDataNames) do
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
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
