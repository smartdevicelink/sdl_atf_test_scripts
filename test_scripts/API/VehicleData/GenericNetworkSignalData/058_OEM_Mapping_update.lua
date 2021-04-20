---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL initiates the OEM mapping update in case VDI were updated

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered
-- 3. PTU is triggered

-- Sequence:
-- 1. PTU is performed with updated VDI and OEM mapping version
-- 2. HMI requests SDL.GetPolicyConfigurationData(policyType = "module_config", property = "endpoint_properties")
--  a. SDL responds to SDL.GetPolicyConfigurationData with endpoint_properties from DB
-- 3. PTU is performed with updated VDI and OEM mapping version
-- 4. HMI sends SDL.GetPolicyConfigurationData(policyType = "module_config", property = "endpoint_properties")
--  a. SDL responds SDL.GetPolicyConfigurationData with endpoint_properties from DB
-- 5. HMI sends SDL.GetPolicyConfigurationData(policyType = "module_config", property = "endpoint")
--  a.  SDL responds to SDL.GetPolicyConfigurationData with endpoint from DB
-- 6. HMI sends BC.OnSystemRequest(requestType = "OEM_SPECIFIC", requestSubType = "VEHICLE_DATA_MAPPING",
--   fileType = "JSON", url) to SDL
--  a. SDL resend BC.OnSystemRequest to mobile app
-- 7. Mobile app sends SystemRequest(requestType = "OEM_SPECIFIC", requestSubType = "VEHICLE_DATA_MAPPING") to
--   SDL with OEM mapping schema
--  a. SDL sends BC.SystemRequest(requestType = "OEM_SPECIFIC", requestSubType = "VEHICLE_DATA_MAPPING") to HMI
-- 8. HMI responds with success resultCode to BC.SystemRequest
--  a. SDL sends SystemRequest(SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')
local json = require("modules/json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local preloadedTable = common.getPreloadedFileAndContent()
local endpointsFromPtu
local endpointPropertiesFromPtu
local updatedOemMappingVersion = "0.2.2"
local updatedOemMappingUrl = "http://x.x.x.x:3000/api/1/vehicleDataMapUpd"
local oemMappingFileName = "oemMappingTable.json"
local oemMappingSampleFile = "files/jsons/GenericNetworkSignalData/OEM_Mapping_update.json"
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
        maxlength = 20,
        minlength = 10
      },
      -- updated key
      {
        name = "struct_element_3_flt",
        type = "Float",
        key = "OEM_REF_STRUCT_3_FLT_UPD",
        mandatory = false
      }
    }
  }
}

--[[ Local Functions ]]
local function GetPolicyConfigurationData()
  local requestId = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoint_properties" })
  common.getHMIConnection():ExpectResponse(requestId, { result = {
    value = { json.encode(preloadedTable.policy_table.module_config.endpoint_properties) }}})
end

local function oemMappingUpdate()
  local oemUrl = updatedOemMappingUrl

  local systemRequestParamsFromMobile = {
    requestType = "OEM_SPECIFIC",
    requestSubType = "VEHICLE_DATA_MAPPING",
    fileName = oemMappingFileName
  }
  local systemRequestParamsOnHMI = common.cloneTable(systemRequestParamsFromMobile)
  systemRequestParamsOnHMI.fileName = common:read_parameter_from_smart_device_link_ini("SystemFilesPath") ..
   "/".. oemMappingFileName

  local onSystemRequestParamsFromHMI = common.cloneTable(systemRequestParamsOnHMI)
  onSystemRequestParamsFromHMI.url = oemUrl
  onSystemRequestParamsFromHMI.fileType = "JSON"
  local onSystemRequestParamsOnMobile = common.cloneTable(onSystemRequestParamsFromHMI)
  onSystemRequestParamsOnMobile.fileName = nil

  local requestGetPCD = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoint_properties" })
  common.getHMIConnection():ExpectResponse(requestGetPCD,
    { result = { value = { json.encode(endpointPropertiesFromPtu) } } })
  :Do(function()
      local requestGetPCD2 = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })
      common.getHMIConnection():ExpectResponse(requestGetPCD2)
      :ValidIf(function(_, data)
          return common.validation(json.decode(data.result.value[1]), endpointsFromPtu,
            "endpoints from GetPolicyConfigurationData response ")
        end)
      :Do(function()
          common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest", onSystemRequestParamsFromHMI)
          common.getMobileSession():ExpectNotification("OnSystemRequest", onSystemRequestParamsOnMobile)
          :Do(function()
              local corIdSystemRequest = common.getMobileSession():SendRPC("SystemRequest",
                systemRequestParamsFromMobile, oemMappingSampleFile)
              common.getHMIConnection():ExpectRequest("BasicCommunication.SystemRequest", systemRequestParamsOnHMI)
              :Do(function(_, data)
                  common.getHMIConnection():SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                end)
              common.getMobileSession():ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
              :ValidIf(function()
                  if common.isFileExist(systemRequestParamsOnHMI.fileName) then
                    local fileContent = common.jsonFileToTable(systemRequestParamsOnHMI.fileName)
                    local oemMappingSample = common.jsonFileToTable(oemMappingSampleFile)
                    return common.validation(fileContent, oemMappingSample, "OEM mapping file ")
                  end
                  return false, "OEM mapping file is absent on FS in " .. systemRequestParamsOnHMI.fileName
                end)
            end)
        end)
    end)
end

local function ptuFuncVDIupdate(pTbl)
  common.ptuFuncWithCustomData(pTbl)
  for anotherKey, anotherValue in pairs(anotherCustomDataType) do
    for key, value in pairs(pTbl.policy_table.vehicle_data.schema_items) do
      if value.name == anotherValue.name then
        pTbl.policy_table.vehicle_data.schema_items[key] = anotherCustomDataType[anotherKey]
      end
    end
  end
  pTbl.policy_table.module_config.endpoint_properties.custom_vehicle_data_mapping_url.version = updatedOemMappingVersion
  pTbl.policy_table.module_config.endpoints.custom_vehicle_data_mapping_url.default[1] = updatedOemMappingUrl
  endpointsFromPtu = pTbl.policy_table.module_config.endpoints
  endpointPropertiesFromPtu = pTbl.policy_table.module_config.endpoint_properties
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Get OEM mapping version before update", GetPolicyConfigurationData)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { ptuFuncVDIupdate })
runner.Step("OEM mapping update", oemMappingUpdate)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
