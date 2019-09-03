---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying mandatory value for Child-level VD

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains the custom VD items in VehicleDataItems with
--   child_data_1 mandatory(mandatory=true) child parameter and child_data_2 non-mandatory(mandatory=false)
-- 4. Custom VD is allowed
-- 5. App is subscribed for custom VD

-- Sequence:
-- 1.HMI sends OnVD with mandatory and non-mandatory child parameter in custom VD
--   a. SDL resends OnVD notification to mobile app
-- 2.HMI sends OnVD with only mandatory child parameter in custom VD
--   a. SDL resends OnVD notification to mobile app
-- 3.HMI sends OnVD without mandatory child parameter and with non-mandatory child parameter in custom VD
--   a. SDL does not send OnVD to mobile app
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

local VDIitem11StructHMIreqParamsRpcSpec = common.getHMIrequestData("custom_vd_item11_struct")

--[[ Local Functions ]]
local function getOnlyMandatoryParams()
  local onlyMandatory = common.cloneTable(common.VehicleDataItemsWithData.custom_vd_item11_struct.params)
  for vehicleDataName in pairs(onlyMandatory) do
    if onlyMandatory[vehicleDataName].mandatory ~= true then
      onlyMandatory[vehicleDataName] = nil
    end
  end
  return onlyMandatory
end

local function getOnlyNonMandatoryParams()
  local onlyNonMandatory = common.cloneTable(common.VehicleDataItemsWithData.custom_vd_item11_struct.params)
  for vehicleDataName in pairs(onlyNonMandatory) do
    if onlyNonMandatory[vehicleDataName].mandatory == true then
      onlyNonMandatory[vehicleDataName] = nil
    end
  end
  return onlyNonMandatory
end

local function setNewStructParams(pValue)
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params = pValue
end

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

local function GetVDwithDiferentReqAndResExp(pData)
  local mobRequestData = { [common.VehicleDataItemsWithData[pData].name] = true }
  local hmiRequestData = VDIitem11StructHMIreqParamsRpcSpec
  local hmiResponseData, mobileResponseData = common.getVehicleDataResponse(pData)
  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)

  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "WARNINGS", hmiResponseData)
  end)
  :ValidIf(function(_,data)
    if true ~= common:is_table_equal(data.params, hmiRequestData) then
        return false, "VehicleInfo.GetVehicleData contains unexpected parameters.\n" ..
        "Expected table: " .. common.tableToString(hmiRequestData) .. "\n" ..
        "Actual table: " .. common.tableToString(data.params) .. "\n"
    end
    return true
  end)
  mobileResponseData.success = true
  mobileResponseData.resultCode = "WARNINGS"
  common.getMobileSession():ExpectResponse(cid, mobileResponseData)
  :ValidIf(function(_,data)
    if true ~= common:is_table_equal(data.payload, mobileResponseData) then
        return false, "GetVehicleData response contains unexpected parameters.\n" ..
        "Expected table: " .. common.tableToString(mobileResponseData) .. "\n" ..
        "Actual table: " .. common.tableToString(data.payload) .. "\n"
    end
    return true
  end)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
runner.Step("SubscribeVehicleData to custom_vd_item11_struct", common.VDsubscription,
  { appSessionId, "custom_vd_item11_struct", "SubscribeVehicleData" })
runner.Step("OnVehicleData for custom_vd_item11_struct with mandatory and non-mandatory params", common.onVD,
  { appSessionId, "custom_vd_item11_struct"  })
runner.Step("GetVehicleData for custom_vd_item11_struct with mandatory and non-mandatory params", common.GetVD,
  { appSessionId, "custom_vd_item11_struct" })

runner.Step("Set only mandatory params in custom_vd_item11_struct", setNewStructParams, { getOnlyMandatoryParams() })
runner.Step("OnVehicleData for custom_vd_item11_struct with only mandatory params", common.onVD,
  { appSessionId, "custom_vd_item11_struct" })
runner.Step("GetVehicleData for custom_vd_item11_struct with only mandatory params", GetVDwithDiferentReqAndResExp,
  { "custom_vd_item11_struct" })

runner.Step("Set only non-mandatory params in custom_vd_item11_struct", setNewStructParams,
  { getOnlyNonMandatoryParams() })
runner.Step("OnVehicleData for custom_vd_item11_struct without mandatory params", common.onVD,
  { appSessionId, "custom_vd_item11_struct", common.VD.NOT_EXPECTED })
runner.Step("GetVehicleData for custom_vd_item11_struct without mandatory params", getVehicleDataGenericError,
  { "custom_vd_item11_struct" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
