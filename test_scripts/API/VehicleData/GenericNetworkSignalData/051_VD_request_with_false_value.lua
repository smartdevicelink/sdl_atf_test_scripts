---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description:Processing VD requests with parameter=false

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData are allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VehicleData from VehicleDataItems are defined in parameters of functional group for application

-- Sequence:
-- 1. SubscribeVD/UnsubscribeVD/GetVD is requested from mobile app with VDparams = false and VDpdarams = true
--   a. SDL sends request only with VDparams = true to HMI
-- 2. HMI responds with successful response with VDparams to SDL
--   a. SDL processes successful response from HMI
--   b. SDL sends successful response with received params to mobile app
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
local function VDsubscription(pRPC)
  local floatItem = common.VehicleDataItemsWithData.custom_vd_item2_float
  local speedItem = common.VehicleDataItemsWithData.speed

  local mobRequestData = {
    custom_vd_item1_integer = false,
    custom_vd_item2_float = true,
    gps = false,
    speed = true
  }

  local hmiRequestData = {
    [floatItem.key] = true,
    [speedItem.name] = true
  }

  local hmiResponseData = {
    [speedItem.name] = {
      dataType = speedItem.APItype,
      resultCode = "SUCCESS"
    },
    [floatItem.key] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }
  }

  local mobileResponseData = {
    [speedItem.name] = hmiResponseData[speedItem.name],
    [floatItem.name] = common.buildSubscribeMobileResponseItem(hmiResponseData[floatItem.key], floatItem.name)
  }

  local cid = common.getMobileSession():SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  :ValidIf(function(_,data)
    return common.validation(data.params, hmiRequestData, "VehicleInfo." .. pRPC)
  end)
  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, mobileResponseData)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileResponseData, pRPC .. " response")
  end)

  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function GetVD()
  local mobRequestData = {
    custom_vd_item1_integer = false,
    custom_vd_item2_float = true,
    gps = false,
    speed = true
  }

  local function getArrayWithKeys(pArray)
    local out = {}
    for _, value in pairs(pArray)do
      local elementKey, elementValue = next(value)
      out[elementKey] = elementValue
    end
    return out
  end

  local hmiRequestDataArray = {
    common.getHMIrequestData("custom_vd_item2_float"),
    common.getHMIrequestData("speed")
  }

  local hmiRequestData = getArrayWithKeys(hmiRequestDataArray)

  local hmiResponseData1, mobileResponseData1 = common.getVehicleDataResponse("custom_vd_item2_float")
  local hmiResponseData2, mobileResponseData2 = common.getVehicleDataResponse("speed")

  local hmiResponseDataArray = {
    hmiResponseData1,
    hmiResponseData2
  }

  local mobileResponseDataArray = {
    mobileResponseData1,
    mobileResponseData2
  }

  local hmiResponseData = getArrayWithKeys(hmiResponseDataArray)
  local mobileResponseData = getArrayWithKeys(mobileResponseDataArray)

  local cid = common.getMobileSession():SendRPC("GetVehicleData", mobRequestData)

  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  :ValidIf(function(_,data)
    return common.validation(data.params, hmiRequestData, "VehicleInfo.GetVehicleData")
  end)
  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, mobileResponseData)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileResponseData, "GetVehicleData response")
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
runner.Step("SubscribeVehicleData", VDsubscription, { "SubscribeVehicleData" })
runner.Step("OnVehicleData custom_vd_item2_float", common.onVD,
  { appSessionId, "custom_vd_item2_float" })
runner.Step("OnVehicleData speed", common.onVD,
  { appSessionId, "speed" })
runner.Step("OnVehicleData custom_vd_item1_integer", common.onVD,
  { appSessionId, "custom_vd_item1_integer", common.VD.NOT_EXPECTED })
runner.Step("OnVehicleData gps", common.onVD,
  { appSessionId, "gps", common.VD.NOT_EXPECTED })
runner.Step("UnsubscribeVehicleData", VDsubscription, { "UnsubscribeVehicleData" })
runner.Step("GetVehicleData", GetVD)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
