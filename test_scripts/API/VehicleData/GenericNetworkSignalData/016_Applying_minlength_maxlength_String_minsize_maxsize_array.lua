---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying of the minsize and maxsize for array of VD, minlength and maxlength for array element
--   with type=String

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains the custom VD items in VehicleDataItems with type=String, array=true,
--   minsize and maxsize,minlength and maxlength
-- 4. Custom VD is allowed
-- 5. App is subscribed for custom VD

-- Sequence:
-- 1. HMI sends OnVD with array size and element length in range for custom VD
--   a. SDL resends OnVD notification to mobile app
-- 2. HMI sends OnVD with array size out of range for custom VD
--   a. SDL does not send OnVD to mobile app
-- 3. HMI sends OnVD with array size in range but with element length in out of range for custom VD
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
      if subVDitem.name == "struct_element_5_array" then
        common.customDataTypeSample[VDkey].params[subVDkey].minvalue = nil
        common.customDataTypeSample[VDkey].params[subVDkey].maxvalue = nil
        common.customDataTypeSample[VDkey].params[subVDkey].type = "String"
        common.customDataTypeSample[VDkey].params[subVDkey].minlength = 3
        common.customDataTypeSample[VDkey].params[subVDkey].maxlength = 7
      end
    end
  end
end

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1
local paramsForChecking = { "custom_vd_item6_array_string", "custom_vd_item11_struct" }
local arrayMinSize = common.EMPTY_ARRAY

local function getItemParamValues(pItem)
  local params = {}
  local stringMinLength = string.rep("a",pItem.minlength)
  local stringMaxLength = string.rep("a",pItem.maxlength)

  params.arrayMaxSizeMinLength = { }
  params.arrayMaxSizeMaxLength = { }
  for i = 1, pItem.maxsize do
    params.arrayMaxSizeMinLength[i] = stringMinLength
    params.arrayMaxSizeMaxLength[i] = stringMaxLength
  end

  params.arrayOutOfMaxSize = common.cloneTable(params.arrayMaxSizeMaxLength)
  table.insert(params.arrayOutOfMaxSize, stringMaxLength)

  params.arrayOutOfMaxLength = { stringMaxLength .. "a" }

  return params
end

local rootItemParams = getItemParamValues(common.VehicleDataItemsWithData.custom_vd_item6_array_string)
local childItemParams = getItemParamValues(
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_5_array)

--[[ Local Functions ]]
local function setNewArrayValues(pValueRootLevel, pValueChildLevel)
  common.VehicleDataItemsWithData.custom_vd_item6_array_string.value = pValueRootLevel
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_5_array.value = pValueChildLevel
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

runner.Step("Update parameter values to minsize", setNewArrayValues, { arrayMinSize, arrayMinSize })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData minsize " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to minlength, maxsize", setNewArrayValues,
  { rootItemParams.arrayMaxSizeMinLength, childItemParams.arrayMaxSizeMinLength })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData minlength, maxsize " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to maxlength, maxsize", setNewArrayValues,
  { rootItemParams.arrayMaxSizeMaxLength, childItemParams.arrayMaxSizeMaxLength })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData maxlength, maxsize " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to out of maxlength", setNewArrayValues,
  { rootItemParams.arrayOutOfMaxLength, childItemParams.arrayOutOfMaxLength })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData out of maxlength " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Step("Update parameter values to out of maxsize", setNewArrayValues,
  { rootItemParams.arrayOutOfMaxSize, childItemParams.arrayOutOfMaxSize })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData out of maxsize " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
