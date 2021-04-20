---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing GetVD/OnVD RPC's in case HMI sends VD values not according to schema

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group

-- Sequence:
-- 1. GetVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.GetVD to HMI
-- 2. HMI responds with VD not according to schema(invalid type)
--   a. SDL processes response from HMI
--   b. SDL sends response(GENERIC_ERROR) to mobile app
-- 3. HMI sends OnVD notification with VD(not according to schema(invalid type)
--   a. SDL does not send the OnVD notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)

local function setValuesForCustomDataWithInvalidType()
  common.VehicleDataItemsWithData.custom_vd_item1_integer.value = "50"
  common.VehicleDataItemsWithData.custom_vd_item2_float.value = true
  common.VehicleDataItemsWithData.custom_vd_item3_enum.value = 10
  common.VehicleDataItemsWithData.custom_vd_item4_string.value = 100
  common.VehicleDataItemsWithData.custom_vd_item5_boolean.value = "true"
  common.VehicleDataItemsWithData.custom_vd_item6_array_string.value = { "string_el_1", "string_el_2", 10 }
  common.VehicleDataItemsWithData.custom_vd_item7_array_integer.value = "{ 1, 2, 3, 4, 5 }"
  common.VehicleDataItemsWithData.custom_vd_item8_array_float.value = { 1, 2, 3.5, 4.5, "5.5" }
  common.VehicleDataItemsWithData.custom_vd_item9_array_enum.value = "ON"
  common.VehicleDataItemsWithData.custom_vd_item10_array_bool.value = { false, "true" }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_1_int.value = 100.777
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_2_str.value = 100
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_3_flt.value = "100.10"
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_4_enum.value = { "NO_DATA_EXISTS" }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_5_array.value = { "100" }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_6_struct.params.substruct_element_1_int.value = { 100, "500", 300 }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_6_struct.params.substruct_element_2_bool.value = "false"
end

setValuesForCustomDataWithInvalidType()

local appSessionId = 1

--[[ Local Functions ]]
local function getVehicleDataGenericError(pData)
  local mobRequestData = { [common.VehicleDataItemsWithData[pData].name] = true }
  local hmiRequestData = common.getHMIrequestData(pData)
  local hmiResponseData = common.getVehicleDataResponse(pData)

  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
for _, vehicleDataItem in pairs(common.customDataTypeSample) do
  runner.Step("SubscribeVehicleData " .. vehicleDataItem.name, common.VDsubscription,
    { appSessionId, vehicleDataItem.name, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataItem.name, common.onVD,
    { appSessionId, vehicleDataItem.name, common.VD.NOT_EXPECTED })
  runner.Step("GetVehicleData " .. vehicleDataItem.name, getVehicleDataGenericError,
    { vehicleDataItem.name })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
