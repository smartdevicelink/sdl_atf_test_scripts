---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Ignoring mandatory: true for root-level

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains the custom vehicle data_1 mandatory=true for Root-Level
-- 4. Custom vehicle data_1 and RPC spec vehicle data_2 are allowed
-- 5. App is subscribed for custom vehicle data_1 and RPC spec vehicle data_2

-- Sequence:
-- 1. HMI sends OnVD without custom data_1, but with data_2
--   a. SDL resends OnVD(data_2) notification to mobile app
-- 2. GetVD is requested only with data_2 from mobile app
--   a. SDL sends VI.GetVehicleData(data_2)
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
for VDkey, VDitem in pairs (common.customDataTypeSample)do
  if VDitem.name == "custom_vd_item1_integer" then
    common.customDataTypeSample[VDkey].mandatory = true
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
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
runner.Step("SubscribeVehicleData to custom_vd_item2_float without custom_vd_item1_integer", common.VDsubscription,
  { appSessionId, "custom_vd_item2_float", "SubscribeVehicleData" })
runner.Step("SubscribeVehicleData to custom_vd_item1_integer", common.VDsubscription,
  { appSessionId, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("OnVehicleData for custom_vd_item2_float without custom_vd_item1_integer", common.onVD,
  { appSessionId, "custom_vd_item2_float" })
runner.Step("OnVehicleData for custom_vd_item1_integer", common.onVD, { appSessionId, "custom_vd_item1_integer" })
runner.Step("GetVehicleData for custom_vd_item2_float without custom_vd_item1_integer", common.GetVD,
  { appSessionId, "custom_vd_item2_float" })
runner.Step("GetVehicleData for custom_vd_item1_integer", common.GetVD, { appSessionId, "custom_vd_item1_integer" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
