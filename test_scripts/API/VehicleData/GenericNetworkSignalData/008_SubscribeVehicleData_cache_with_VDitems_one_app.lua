---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Cache of the subscription for RPC spec and custom VehicleDataItems with one app

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. VehicleData is allowed by policies
-- 3. Mobile app is registered
-- 4. App is activated
-- 5. PTU is performed with VehicleDataItems in update file

-- Sequence:
-- 1. SubscribeVD(data_1) is requested from mobile app
--   a. SDL sends VI.SubscribeVD(data_1) to HMI
-- 2. HMI responds with successful response to SDL
--   a. SDL processes successful response from HMI
--   b. SDL sends successful response to mobile app
-- 3. HMI sends OnVD(data_1) notification with subscribed data
--   a. SDL resends the OnVD notification to mobile app
-- 4. SubscribeVD(data_1, data_2) is requested from mobile app
--   a. SDL sends VI.SubscribeVD(data_2) to HMI
--   b. SDL sends successful response to mobile app with SUCCESS code for data_2 and
--      with DATA_ALREADY_SUBSCRIBED code for data_1
-- 5. HMI sends OnVD(data_1) notification
--   a. SDL resends the OnVD notification to mobile app
-- 6. HMI sends OnVD(data_2) notification
--   a. SDL resends the OnVD notification to mobile app
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
local function processingVD()
  local mobRequestData = {
    gps = true,
    custom_vd_item1_integer = true,
    custom_vd_item2_float = true
  }

  local hmiRequestData = {
    gps = true,
    [common.VehicleDataItemsWithData.custom_vd_item2_float.key] = true
  }

  local VDItemResponse = { dataType = common.CUSTOM_DATA_TYPE, resultCode = "SUCCESS" }
  local gpsResponse = { dataType = common.VehicleDataItemsWithData.gps.APItype, resultCode = "SUCCESS" }

  local hmiResponseData = {
    [common.VehicleDataItemsWithData.custom_vd_item2_float.key] = VDItemResponse,
    gps = gpsResponse
  }

  local floatItem = common.VehicleDataItemsWithData.custom_vd_item2_float
  local integerItem = common.VehicleDataItemsWithData.custom_vd_item1_integer
  local MobResp = {
    gps = gpsResponse,
    [floatItem.name] = common.buildSubscribeMobileResponseItem(VDItemResponse, floatItem.name),
    [integerItem.name] = common.buildSubscribeMobileResponseItem(
        { dataType = common.CUSTOM_DATA_TYPE, resultCode = "DATA_ALREADY_SUBSCRIBED" }, integerItem.name)
  }

  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)

  MobResp.success = true
  MobResp.resultCode = "IGNORED"
  MobResp.info = "Already subscribed on some provided VehicleData."
  common.getMobileSession():ExpectResponse(cid, MobResp)
  :ValidIf(function(_, data)
    local isEqual = common:is_table_equal(data.payload, MobResp)
    if isEqual == false then
      return false, "SubscribeVehicleData response contains unexpected params.\n" ..
      "Expected:\n" .. common.tableToString(MobResp) ..
      "\nActual:\n" .. common.tableToString(data.payload)
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
runner.Step("SubscribeVehicleData custom_vd_item1_integer", common.VDsubscription,
  { appSessionId, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("OnVehicleData custom_vd_item1_integer", common.onVD, { appSessionId, "custom_vd_item1_integer" })
runner.Step("SubscribeVehicleData custom_vd_item1_integer, gps, custom_vd_item2_float", processingVD)
runner.Step("OnVehicleData custom_vd_item1_integer", common.onVD, { appSessionId, "custom_vd_item1_integer" })
runner.Step("OnVehicleData custom_vd_item2_float", common.onVD, { appSessionId, "custom_vd_item2_float" })
runner.Step("OnVehicleData gps", common.onVD, { appSessionId, "gps" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
