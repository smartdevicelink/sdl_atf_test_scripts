---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying of the minvalue and maxnvalue for Float VD type

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains the custom VD items in VehicleDataItems with type=Float and
--   minvalue, maxvalue
-- 4. Custom VD is allowed
-- 5. App is subscribed for custom VD

-- Sequence:
-- 1. HMI sends OnVD with float value in range for custom VD
--   a. SDL resends OnVD notification to mobile app
-- 2. HMI sends OnVD with float value out of range for custom VD
--   a. SDL does not send OnVD to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
for VDkey, VDitem in pairs (common.customDataTypeSample)do
  if VDitem.name == "custom_vd_item11_struct" then
    for subVDkey, subVDitem in pairs(VDitem.params) do
      if subVDitem.name == "struct_element_3_flt" then
        common.customDataTypeSample[VDkey].params[subVDkey].minvalue = 0.5
        common.customDataTypeSample[VDkey].params[subVDkey].maxvalue = 50.99
      end
    end
  end
end

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1
local paramsForChecking = { "custom_vd_item2_float", "custom_vd_item11_struct" }

--[[ Local Functions ]]
local function setNewFloatValues(pValueRootLevel, pValueChildLevel)
  common.VehicleDataItemsWithData.custom_vd_item2_float.value = pValueRootLevel
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_3_flt.value = pValueChildLevel
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
end

runner.Step("Update parameter values to minvalue", setNewFloatValues, { 1, 0.5 })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData minvalue " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to maxvalue", setNewFloatValues, { 100.5, 50.99 })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData maxvalue " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to out of minvalue", setNewFloatValues, { 0.9, 0.4 })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData out of minvalue " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Step("Update parameter values to out of maxvalue", setNewFloatValues, { 100.99, 51 })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData out of maxvalue " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
