---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying of the update for VehicleDataItems from PTU after already successful one

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains VehicleDataItems with custom VD items
-- 4. New PTU is triggered

-- Sequence:
-- 1. Mobile app receives the update with updated VehicleDataItems(with updated, removed, added items) and provides it to SDL
--   a. SDL applies the update, saves it to DB
--   b. SDL sends OnPermissionChange with VehicleData according to update to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
local appSessionId = 1
local anotherCustomDataType = {
  -- update minvalue and maxvalue
  {
    name = "custom_vd_item1_integer",
    type = "Integer",
    key = "OEM_REF_INT",
    array = false,
    mandatory = false,
    minvalue = 100,
    maxvalue = 1000
  },
  -- removed custom_vd_item2_float item

  -- update enum
  {
    name = "custom_vd_item3_enum",
    type = "VehicleDataEventStatus",
    key = "OEM_REF_Enum",
    array = false,
    mandatory = false
  },
  -- updated minlength and maxlength
  {
    name = "custom_vd_item4_string",
    type = "String",
    key = "OEM_REF_STR",
    array = false,
    mandatory = false,
    params = common.EMPTY_ARRAY,
    minlength = 15,
    maxlength = 100
  },
  -- without changes
  {
    name = "custom_vd_item5_boolean",
    type = "Boolean",
    key = "OEM_REF_BOOL",
    array = false,
    mandatory = false
  },
  -- updated minlength, maxlength and minsize, maxsize
  {
    name = "custom_vd_item6_array_string",
    type = "String",
    key = "OEM_REF_ARR_STR",
    array = true,
    mandatory = false,
    minsize = 10,
    maxsize = 20,
    minlength = 5,
    maxlength = 15
  },
  -- updated key value
  {
    name = "custom_vd_item7_array_integer",
    type = "Integer",
    key = "OEM_REF_ARR_INT_UPD",
    array = true,
    mandatory = false,
    minsize = 0,
    maxsize = 50,
    minvalue = 0,
    maxvalue = 100
  },
  -- updated minvalue, minvalue and minsize, maxsize
  {
    name = "custom_vd_item8_array_float",
    type = "Float",
    key = "OEM_REF_ARR_FLOAT",
    array = true,
    mandatory = false,
    minsize = 5,
    maxsize = 10,
    minvalue = 10,
    maxvalue = 20
  },
  -- updated array, type with params
  {
    name = "custom_vd_item9_array_enum",
    type = "Struct",
    key = "OEM_REF_ENUM",
    array = false,
    mandatory = false,
    params = {
      {
        name = "Struct_element_upd",
        type = "Integer",
        key = "OEM_REF_STRUCT_UPD",
        mandatory = true
      }
    }
  },
  -- without changes
  {
    name = "custom_vd_item10_array_bool",
    type = "Boolean",
    key = "OEM_REF_ARR_BOOL",
    array = true,
    mandatory = false,
    minsize = 0,
    maxsize = 50
  },
  -- updated elements in struct
  {
    name = "custom_vd_item11_struct",
    type = "Struct",
    key = "OEM_REF_STRUCT",
    mandatory = false,
    params = {
      -- update mandatory
      {
        name = "struct_element_1_int",
        type = "Integer",
        key = "OEM_REF_STRUCT_1_INT",
        mandatory = false,
        minsize = 0,
        maxsize = 5,
        minvalue = 0,
        maxvalue = 1000
      },
      -- added maxlength and minlength
      {
        name = "struct_element_2_str",
        type = "String",
        key = "OEM_REF_STRUCT_2_STR",
        mandatory = true,
        minlength = 10,
        maxlength = 20
      },
      -- updated key
      {
        name = "struct_element_3_flt",
        type = "Float",
        key = "OEM_REF_STRUCT_3_FLT_UPD",
        mandatory = false
      },
      -- no changes
      {
        name = "struct_element_4_enum",
        type = "VehicleDataStatus",
        key = "OEM_REF_STRUCT_4_Enum",
        mandatory = false
      },
      -- removed struct_element_5_array
      {
        name = "struct_element_6_struct",
        type = "Struct",
        key = "OEM_REF_STRUCT_6_STRUCT",
        mandatory = false,
        params = {
          -- removed substruct_element_1_int

          -- added substruct_element_1_int_upd
          {
            name = "substruct_element_1_int_upd",
            type = "Integer",
            key = "OEM_REF_SUB_STRUCT_1_INT_UPD",
            mandatory = false,
            array = true
          },
          -- become array
          {
            name = "SubStruct_element_2_array_bool",
            type = "Boolean",
            key = "OEM_REF_SUB_STRUCT_2_ARRAY_BOOL",
            mandatory = false,
            array = true
          }
        }
      },
      -- added new Struct_element_7_enum_new
      {
        name = "Struct_element_7_enum_new",
        type = "VehicleDataStatus",
        key = "OEM_REF_STRUCT_7_ENIM_NEW",
        mandatory = false
      },
    }
  },
  -- added new custom_vd_item1_integer_new
  {
    name = "custom_vd_item1_integer_new",
    type = "Integer",
    key = "OEM_REF_INT_NEW",
    array = false,
    mandatory = false,
    minvalue = 100,
    maxvalue = 1000
  }
}
local removedItems = { "custom_vd_item2_float", "struct_element_5_array", "substruct_element_1_int" }

--[[ Local Functions ]]
local function updateVDitemsWithNewData()
  common.writeCustomDataToGeneralArray(anotherCustomDataType)

  common.VehicleDataItemsWithData.custom_vd_item2_float = nil
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_5_array = nil
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_6_struct.params.substruct_element_1_int = nil

  common.VehicleDataItemsWithData.custom_vd_item1_integer.value = 500
  common.VehicleDataItemsWithData.custom_vd_item3_enum.value = "NO_EVENT"
  common.VehicleDataItemsWithData.custom_vd_item5_boolean.value = true
  common.VehicleDataItemsWithData.custom_vd_item4_string.value = " Some  string new "
  common.VehicleDataItemsWithData.custom_vd_item6_array_string.value = {}
  for i=1,10 do
    table.insert(common.VehicleDataItemsWithData.custom_vd_item6_array_string.value, "string_el_" .. i )
  end
  common.VehicleDataItemsWithData.custom_vd_item7_array_integer.value = { 1, 2, 3, 4, 5 }
  common.VehicleDataItemsWithData.custom_vd_item8_array_float.value = { 11, 12, 13.5, 14.5, 15.5 }
  common.VehicleDataItemsWithData.custom_vd_item9_array_enum.params.Struct_element_upd.value = 10
  common.VehicleDataItemsWithData.custom_vd_item10_array_bool.value = { false, true }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_1_int.value = nil
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_2_str.value = "10000000000"
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_3_flt.value = 100.10
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_4_enum.value = "NO_DATA_EXISTS"
  local element6Params = common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_6_struct.params
  element6Params.substruct_element_1_int_upd.value = { 100, 500, 300 }
  element6Params.SubStruct_element_2_array_bool.value = { false, true }
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.Struct_element_7_enum_new.value = "OFF"
  common.VehicleDataItemsWithData.custom_vd_item1_integer_new.value = 500
end

local function ptuFunc(pTbl)
  pTbl.policy_table.vehicle_data = { }
  pTbl.policy_table.vehicle_data.schema_items = anotherCustomDataType

  pTbl.policy_table.vehicle_data.schema_version = "00.01.01"
  pTbl.policy_table.functional_groupings.NewTestCaseGroup = common.cloneTable(
    pTbl.policy_table.functional_groupings["Emergency-1"])
  local customDataNames = common.cloneTable(common.getCustomAndRpcSpecDataNames())

  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.GetVehicleData.parameters = customDataNames
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.OnVehicleData.parameters = customDataNames
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.SubscribeVehicleData.parameters = customDataNames
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.UnsubscribeVehicleData.parameters = customDataNames
  pTbl.policy_table.app_policies[common.getConfigAppParams(appSessionId).fullAppID].groups = {
    "Base-4", "GroupWithAllRpcSpecVehicleData", "NewTestCaseGroup"
  }
end

local function ptu()
  updateVDitemsWithNewData()
  common.isPTUStarted()
  :Do(function()
    common.policyTableUpdate(ptuFunc)
  end)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_, data)
      return common.onPermissionChangeValidation(data.payload.permissionItem, common.getAllVehicleData())
  end)
  common.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
end

local function RPCprocessingwithRemovedVDitems(pData)
  local mobRequestData = { [pData] = true }
  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange,
  { common.ptuFuncWithCustomData, nil, common.getAllVehicleData()  })
runner.Step("PTU with updated VehicleDataItems", ptu)

runner.Title("Test")
for _, vehicleDataItem in pairs(anotherCustomDataType) do
  runner.Step("SubscribeVehicleData " .. vehicleDataItem.name, common.VDsubscription,
    { appSessionId, vehicleDataItem.name, "SubscribeVehicleData", vehicleDataItem})
  runner.Step("OnVehicleData " .. vehicleDataItem.name, common.onVD,
    { appSessionId, vehicleDataItem.name })
  runner.Step("GetVehicleData " .. vehicleDataItem.name, common.GetVD,
    { appSessionId, vehicleDataItem.name })
end
for _, vehicleDataName in pairs(removedItems) do
  runner.Step("GetVehicleData " .. vehicleDataName, RPCprocessingwithRemovedVDitems,
    { vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
