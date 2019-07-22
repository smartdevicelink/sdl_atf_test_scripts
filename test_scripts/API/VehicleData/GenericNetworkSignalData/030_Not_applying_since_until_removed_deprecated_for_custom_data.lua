---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Ignoring since, until, removed, deprecated parameters for custom VehicleData

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains VehicleDataItems with since, until, removed, deprecated parameters
-- 4. Custom VD is allowed

-- Sequence:
-- 1. SubscribeVD/GetVD/UnsubscribeVD with custom VD is requested from mobile app
--   a. SDL applies last actual item
--   b. SDL processes the requests without any changes
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local itemInteger
local itemEnum
local itemBool

for VDkey, VDitem in pairs (common.customDataTypeSample)do
  if VDitem.name == "custom_vd_item1_integer" then
    common.customDataTypeSample[VDkey]["since"] = "1.0"
    common.customDataTypeSample[VDkey]["until"] = "5.0"
    itemInteger = common.cloneTable(common.customDataTypeSample[VDkey])
    itemInteger.minvalue = 101
    itemInteger.maxvalue = 1000
    itemInteger.since = "5.0"
  elseif VDitem.name == "custom_vd_item3_enum" then
    common.customDataTypeSample[VDkey]["since"] = "1.0"
    common.customDataTypeSample[VDkey]["until"] = "5.0"
    itemEnum = common.cloneTable(common.customDataTypeSample[VDkey])
    itemEnum.array = true
    itemEnum.removed = true
    itemEnum.since = "5.0"
  elseif VDitem.name == "custom_vd_item4_string" then
    common.customDataTypeSample[VDkey].removed = false
  elseif VDitem.name == "custom_vd_item5_boolean" then
    common.customDataTypeSample[VDkey]["since"] = "1.0"
    common.customDataTypeSample[VDkey]["until"] = "5.0"
    itemBool = common.cloneTable(common.customDataTypeSample[VDkey])
    itemBool.array = true
    itemBool.deprecated = true
    itemBool.since = "5.0"
  elseif VDitem.name == "custom_vd_item6_array_string" then
    common.customDataTypeSample[VDkey].deprecated = false
  end
end

table.insert(common.customDataTypeSample, itemInteger)
table.insert(common.customDataTypeSample, itemEnum)
table.insert(common.customDataTypeSample, itemBool)

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1
local onVDNOTexpected = 0
local paramsWithoutParamsUpdate = { "custom_vd_item4_string", "custom_vd_item6_array_string" }
local paramsWithUpdatedParams = { "custom_vd_item1_integer", "custom_vd_item3_enum", "custom_vd_item5_boolean" }

local function setNewParams()
  common.VehicleDataItemsWithData.custom_vd_item1_integer.value = 150
  common.VehicleDataItemsWithData.custom_vd_item3_enum.value = { "OFF" }
  common.VehicleDataItemsWithData.custom_vd_item5_boolean.value = { true }
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

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
for _, vehicleDataName in pairs(paramsWithoutParamsUpdate) do
  runner.Step("SubscribeVehicleData vehicleDataName" .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData" })
  runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD, { appSessionId, vehicleDataName })
end
for _, vehicleDataName in pairs(paramsWithUpdatedParams) do
  runner.Step("SubscribeVehicleData vehicleDataName" .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName, onVDNOTexpected })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData" })
  runner.Step("GetVehicleData " .. vehicleDataName, getVehicleDataGenericError, { vehicleDataName })
end

runner.Step("Update parameter values according to since and until values", setNewParams)
for _, vehicleDataName in pairs(paramsWithUpdatedParams) do
  runner.Step("SubscribeVehicleData vehicleDataName" .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
  runner.Step("UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "UnsubscribeVehicleData" })
  runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD, { appSessionId, vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
