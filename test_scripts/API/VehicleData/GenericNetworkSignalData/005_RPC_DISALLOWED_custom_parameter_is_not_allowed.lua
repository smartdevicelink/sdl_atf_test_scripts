---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Policy prohibition for VehicleDataItems in case VD is not allowed by policies

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains VehicleDataItems with custom VD items
-- 4. Custom VD is not allowed( VD is not included in 'parameters' of functional group )

-- Sequence:
-- 1. SubscribeVD/GetVD/UnsubscribeVD with custom VD is requested from mobile app
--   a. SDL responds with DISALLOWED resultCode to mobile app
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
local allowedParams = { "gps", "custom_vd_item1_integer"}
local notAllowedParams = { "rpm", "custom_vd_item2_float" }

--[[ Local Functions ]]
function common.ptuFuncWithCustomData(pTbl)
  pTbl.policy_table.vehicle_data = { }
  pTbl.policy_table.vehicle_data.schema_items = common.customDataTypeSample
  pTbl.policy_table.vehicle_data.schema_version = "00.00.02"
  pTbl.policy_table.functional_groupings.NewTestCaseGroup = common.cloneTable(pTbl.policy_table.functional_groupings["Emergency-1"])

  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.GetVehicleData.parameters = allowedParams
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.OnVehicleData.parameters = allowedParams
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.SubscribeVehicleData.parameters = allowedParams
  pTbl.policy_table.functional_groupings.NewTestCaseGroup.rpcs.UnsubscribeVehicleData.parameters = allowedParams

  pTbl.policy_table.app_policies[common.getConfigAppParams(1).fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
end

local function processingAllowedAndDisallowedData()
  local mobRequestData = {
    gps = true,
    custom_vd_item1_integer = true,
    rpm = true,
    custom_vd_item2_float = true
  }

  local hmiRequestData = {
    gps = true,
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.key] = true
  }

  local hmiResponseDataGps, mobileResponseDataGps = common.getVehicleDataResponse("gps")
  local hmiResponseDatacustom_vd_item1_integer, mobileResponseDatacustom_vd_item1_integer = common.getVehicleDataResponse("custom_vd_item1_integer")

  local hmiResponseData = {
    gps = hmiResponseDataGps.gps,
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.key] = hmiResponseDatacustom_vd_item1_integer[common.VehicleDataItemsWithData.custom_vd_item1_integer.key]
  }

  local MobResp = {
    gps = mobileResponseDataGps.gps,
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.name] = mobileResponseDatacustom_vd_item1_integer[common.VehicleDataItemsWithData.custom_vd_item1_integer.name]
  }

  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  :ValidIf(function(_,data)
    if data.params.rpm or
      data.params[common.VehicleDataItemsWithData.custom_vd_item2_float.key] then
      return false, "VI.GetVehicleData request contains unexpected params rpm or " ..
      common.VehicleDataItemsWithData.custom_vd_item2_float.key .. ".\n" ..
      "Received parameters are \n" .. common.tableToString(data.params)
    end
    return true
  end)

  MobResp.success = true
  MobResp.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, MobResp)
  :ValidIf(function(_, data)
    if data.payload.rpm or
      data.payload.custom_vd_item2_float then
      return false, "GetVehicleData response contains unexpected params rpm or " ..
      common.VehicleDataItemsWithData.custom_vd_item2_float.name .. ".\n" ..
      "Received parameters are \n" .. common.tableToString(data.params)
    end
    if not data.payload.info then
      return false, "GetVehicleData response does not contain parameter 'info'"
    end
    return true
  end)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange,
  { common.ptuFuncWithCustomData, nil, allowedParams })

for _,vehicleDataName in pairs(allowedParams) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName })
  runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD,
    { appSessionId, vehicleDataName })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData" })
end

for _, vehicleDataName in pairs(notAllowedParams) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName .. "DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "SubscribeVehicleData", "DISALLOWED" })
  runner.Step("GetVehicleData " .. vehicleDataName .. "DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "GetVehicleData", "DISALLOWED" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName .. "DISALLOWED", common.errorRPCprocessing,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData", "DISALLOWED" })
end

runner.Step("GetVehicleData with allowed and not allowed VD", processingAllowedAndDisallowedData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
