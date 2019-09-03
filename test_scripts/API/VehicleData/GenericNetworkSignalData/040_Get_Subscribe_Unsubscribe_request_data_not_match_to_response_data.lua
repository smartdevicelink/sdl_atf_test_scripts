---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing Subscribe/GetVD/Unsubscribe RPC's in case data in response are not match to data in request

-- Precondition:
-- 1.Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group
-- 6. VD is subscribed ( for unsubscribe )

-- Sequence:
-- 1. SubscribeVD/GetVD/UnsubscribeVD with data_1 from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.SubscribeVD/GetVD/UnsubscribeVD to HMI
-- 2. HMI responds with data_2
--   a. SDL processes the response from HMI
--   b. SDL sends response(GENERIC_ERROR) to mobile app
-- 3. SubscribeVD/GetVD/UnsubscribeVD with data_1 from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.SubscribeVD/GetVD/UnsubscribeVD to HMI
-- 4. HMI responds with data_1 and data_2
--   a. SDL processes the response from HMI
--   b. SDL sends response only with requested data_1 to mobile app
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

--[[ Local Functions ]]
local function getVehicleDataGenericErrorNotMatch()
  local mobRequestData = { [common.VehicleDataItemsWithData.custom_vd_item1_integer.name] = true }
  local hmiRequestData = common.getHMIrequestData("custom_vd_item1_integer")
  local hmiResponseData = common.getVehicleDataResponse("custom_vd_item2_float")

  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function getVehicleDataWithRedundant()
  local mobRequestData = { [common.VehicleDataItemsWithData.custom_vd_item1_integer.name] = true }
  local hmiRequestData = common.getHMIrequestData("custom_vd_item1_integer")
  local hmiResponseData, mobileResponseData = common.getVehicleDataResponse("custom_vd_item1_integer")
  local hmiResponseDataFloat = common.getVehicleDataResponse("custom_vd_item2_float")

  for key, value in pairs(hmiResponseDataFloat) do
    hmiResponseData[key] = value
  end

  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)

  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, mobileResponseData)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileResponseData, "GetVehicleData response")
  end)
end

local function subscriptionVDNotMatch(pRPC, pData)
  local mobRequestData = { [common.VehicleDataItemsWithData[pData].name] = true }
  local hmiRequestData
  if pRPC == "UnsubscribeVehicleData" then
    hmiRequestData = { [common.VehicleDataItemsWithData[pData].key] = true }
  else
    hmiRequestData = common.getHMIrequestData(pData)
  end
  local hmiResponseData = {
    [common.VehicleDataItemsWithData.custom_vd_item2_float.key] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }
  }

  local cid = common.getMobileSession():SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)

end

local function subscriptionVDWithRedundant(pRPC, pData)
  local mobRequestData = { [common.VehicleDataItemsWithData[pData].name] = true }
  local hmiRequestData
  if pRPC == "UnsubscribeVehicleData" then
    hmiRequestData = { [common.VehicleDataItemsWithData[pData].key] = true }
  else
    hmiRequestData = common.getHMIrequestData(pData)
  end
  local vdResponseStruct = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }
  local hmiResponseData = {
    [common.VehicleDataItemsWithData[pData].key] = vdResponseStruct,
    [common.VehicleDataItemsWithData.custom_vd_item2_float.key] = vdResponseStruct
  }

  local cid = common.getMobileSession():SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)

  local item = common.VehicleDataItemsWithData[pData]
  local mobileResponseData = { [item.name] = common.buildSubscribeMobileResponseItem(vdResponseStruct, item.name) }
  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, mobileResponseData)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileResponseData, pRPC .. " response")
  end)
  common.getMobileSession():ExpectNotification("OnHashChange")
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })
runner.Step("SubscribeVehicleData", common.VDsubscription,
  { appSessionId, "custom_vd_item11_struct", "SubscribeVehicleData" })

runner.Title("Test")
runner.Step("SubscribeVehicleData GENERIC_ERROR", subscriptionVDNotMatch,
  { "SubscribeVehicleData", "custom_vd_item1_integer" })
runner.Step("UnsubscribeVehicleData GENERIC_ERROR", subscriptionVDNotMatch,
  { "UnsubscribeVehicleData", "custom_vd_item11_struct" })
runner.Step("SubscribeVehicleData with redundant param", subscriptionVDWithRedundant,
  { "SubscribeVehicleData", "custom_vd_item1_integer" })
runner.Step("UnsubscribeVehicleData with redundant param", subscriptionVDWithRedundant,
  { "UnsubscribeVehicleData", "custom_vd_item11_struct" })
runner.Step("GetVehicleData GENERIC_ERROR", getVehicleDataGenericErrorNotMatch)
runner.Step("GetVehicleData with redundant param", getVehicleDataWithRedundant)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
