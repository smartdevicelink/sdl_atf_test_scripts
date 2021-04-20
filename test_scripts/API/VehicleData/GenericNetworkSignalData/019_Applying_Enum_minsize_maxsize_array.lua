---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying of the minsize and maxsize for array of VD with type=Enum

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains the custom VD items in VehicleDataItems with type=Some_enum_from_API,
--   array=true, minsize and maxsize,minvalue and maxvalue
-- 4. Custom VD is allowed
-- 5. App is subscribed for custom VD

-- Sequence:
-- 1. HMI sends OnVD with array size and element value in range for custom VD
--   a. SDL resends OnVD notification to mobile app
-- 2. HMI sends OnVD with array size out of range for custom VD
--   a. SDL does not send OnVD to mobile app
-- 3. HMI sends OnVD with array size in range but with element value in out of range for custom VD
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
        common.customDataTypeSample[VDkey].params[subVDkey].type = "VehicleDataStatus"
      end
    end
  end
end

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1
local paramsForChecking = { "custom_vd_item9_array_enum", "custom_vd_item11_struct" }
local arrayMinSize = common.EMPTY_ARRAY
local arrayOutOfRangeValue = { "Some_enum_value" }

-- parameter values for root element
local rootArrayMaxSize = { }
for i=1,common.VehicleDataItemsWithData.custom_vd_item9_array_enum.maxsize do
  rootArrayMaxSize[i] = "OFF"
end

local rootArrayOutOfMaxSize = common.cloneTable(rootArrayMaxSize)
table.insert(rootArrayOutOfMaxSize, "ON")

-- parameter values for child element
local childArrayMaxSize = { }
for i=1,common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_5_array.maxsize do
  childArrayMaxSize[i] = "ON"
end

local childArrayOutOfMaxSize = common.cloneTable(childArrayMaxSize)
table.insert(childArrayOutOfMaxSize, "OFF")

--[[ Local Functions ]]
local function setNewArrayValues(pValueRootLevel, pValueChildLevel)
  common.VehicleDataItemsWithData.custom_vd_item9_array_enum.value = pValueRootLevel
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
  runner.Step("OnVehicleData minsize " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to maxsize", setNewArrayValues, { rootArrayMaxSize, childArrayMaxSize })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData maxsize " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to out of enum range", setNewArrayValues,
  { arrayOutOfRangeValue, arrayOutOfRangeValue })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData out of enum range " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Step("Update parameter values to out of maxsize", setNewArrayValues,
  { rootArrayOutOfMaxSize, childArrayOutOfMaxSize })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData maxsize " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
