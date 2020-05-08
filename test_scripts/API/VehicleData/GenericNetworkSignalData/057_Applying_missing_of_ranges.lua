---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing of values without ranges for Integer and Float data type

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains VehicleDataItems with custom VD items with type Integer and Float
--   and without max and min values
-- 4. Custom VD is allowed
-- 5. App is subscribed to VD

-- Sequence:
-- 1. HMI sends OnVD with max and min values for 32 bit system
--   a. SDL resends OnVD notification to mobile app
-- 2. GetVD is requested from mobile app
--   a. SDL sends VI.GetVehicleData to HMI
-- 3. HMI responds with successful response with max and min values for 32 bit system to SDL
--   a. SDL processes successful response from HMI
--   b. SDL sends successful response to mobile app
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
local values = {
  int = {
    maxValue = 4294967295,
    minValue = -2147483647
  },
  float = {
    minValue = 1.175494*10^-38,
    maxValue = 3.402823*10^38
  }
}

--[[ Local Functions ]]
local function setNewIntValues(pValueInt, pValueFloat)
  if pValueInt then
    common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_6_struct.params.substruct_element_1_int.value = { pValueInt }
  else
    common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_3_flt.value = pValueFloat
  end
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
runner.Step("SubscribeVehicleData custom_vd_item11_struct", common.VDsubscription,
  { appSessionId, "custom_vd_item11_struct", "SubscribeVehicleData" })

for key, typeValue in pairs(values.int) do
  runner.Step("Update Integer parameter value to " .. key, setNewIntValues, { typeValue })
  runner.Step("OnVehicleData substruct_element_1_int with " .. key, common.onVD, { appSessionId, "custom_vd_item11_struct" })
  runner.Step("GetVehicleData substruct_element_1_int with " .. key, common.GetVD, { appSessionId, "custom_vd_item11_struct" })
end

for key, typeValue in pairs(values.float) do
  runner.Step("Update Float parameter value to " .. key, setNewIntValues, { nil, typeValue })
  runner.Step("OnVehicleData struct_element_3_flt with " .. key, common.onVD, { appSessionId, "custom_vd_item11_struct" })
  runner.Step("GetVehicleData struct_element_3_flt with " .. key, common.GetVD, { appSessionId, "custom_vd_item11_struct" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
