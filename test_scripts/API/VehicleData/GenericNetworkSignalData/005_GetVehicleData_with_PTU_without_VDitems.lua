---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: GetVD for RPC spec VD data from preloaded file after PTU without VehicleDataItems

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed without VehicleDataItems in update file

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

--[[ Local Functions ]]
local function ptuFunc(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams(appSessionId).fullAppID].groups = {
    "Base-4", "GroupWithAllRpcSpecVehicleData", "Base-6"
  }
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU w/o VehicleDataItems", common.policyTableUpdateWithOnPermChange, { ptuFunc })

runner.Title("Test")
for vehicleDataName in pairs(common.VehicleDataItemsWithData) do
  runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD,
    { appSessionId, vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
