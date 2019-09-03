---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Cache of the unsubscription for RPC spec and custom VehicleDataItems with several apps
--
-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. VehicleData is allowed by policies
-- 3. 2 apps are registered
-- 4. App1 is activated
-- 5. PTU is performed with VehicleDataItems in update file
-- 6. App1 and app2 are subscribed for data_1
-- 7. App1 is subscribed for data_2
--
-- Sequence:
-- 1. HMI sends OnVD(data_1) notification
--   a. SDL resends the OnVD notification to mobile app1 and app2
-- 2. HMI sends OnVD(data_2) notification
--   a. SDL resends the OnVD notification to mobile app1
-- 3. UnsubscribeVD(data_1, data_2) is requested from mobile app1
--   a. SDL sends VI.UnsubscribeVD(data_2) to HMI
--   b. SDL sends successful response to mobile app1 for data_1 and data_2
-- 4. HMI sends OnVD(data_1) notification
--   a. SDL does not resend the OnVD notification to mobile app1
--   b. SDL sends OnVD notification to mobile app2
-- 5. HMI sends OnVD(data_2) notification
--   a. SDL does not resend the OnVD notification to mobile app1
-- 6. App2 is activated
-- 7. UnsubscribeVD(data_1) is requested from mobile app2
--   a. SDL sends VI.UnsubscribeVD to HMI
-- 8. HMI responds with successful response to SDL
--   a. SDL processes successful response from HMI
--   b. SDL sends successful response to mobile app2
-- 9. HMI sends OnVD(data_1) notification
--   a. SDL does not resend the OnVD notification to mobile app1 and mobile app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionIdForApp1 = 1
local appSessionIdForApp2 = 2

--[[ Local Functions ]]
local function processingVDunsubscribeWithSeveralData()
  local mobRequestData = {
    [common.VehicleDataItemsWithData.custom_vd_item1_integer.name] = true,
    [common.VehicleDataItemsWithData.custom_vd_item2_float.name] = true
  }

  local hmiRequestData = {
    [common.VehicleDataItemsWithData.custom_vd_item2_float.key] = true
  }

  local hmiResponseData = {
    [common.VehicleDataItemsWithData.custom_vd_item2_float.key] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }
  }

  local floatItem = common.VehicleDataItemsWithData.custom_vd_item2_float
  local integerItem = common.VehicleDataItemsWithData.custom_vd_item1_integer
  local mobileResponseData = {
    [integerItem.name] = common.buildSubscribeMobileResponseItem(hmiResponseData[floatItem.key], integerItem.name),
    [floatItem.name] = common.buildSubscribeMobileResponseItem(hmiResponseData[floatItem.key], floatItem.name)
  }

  local cid = common.getMobileSession(appSessionIdForApp1):SendRPC("UnsubscribeVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", hmiRequestData)
  :ValidIf(function(_, data)
      if
        data.params[common.VehicleDataItemsWithData.custom_vd_item1_integer.key] or
        data.params[common.VehicleDataItemsWithData.custom_vd_item1_integer.name] then
          return false, "VehicleInfo.SubscribeVehicleData contains unexpected data for custom_vd_item1_integer"
      end
      return true
    end)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)

  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession(appSessionIdForApp1):ExpectResponse(cid, mobileResponseData)
  common.getMobileSession(appSessionIdForApp1):ExpectNotification("OnHashChange")
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ApplicationListUpdateTimeout=4000", common.setSDLIniParameter,
  { "ApplicationListUpdateTimeout", 4000 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerAppWOPTU)
runner.Step("App2 registration", common.registerAppWOPTU, { appSessionIdForApp2 })
runner.Step("App1 activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.ptuWithPolicyUpdateReq, { common.ptuFuncWithCustomData2Apps })
runner.Step("App2 activation", common.activateApp, { appSessionIdForApp2 })
runner.Step("App1 SubscribeVehicleData custom_vd_item1_integer", common.VDsubscription,
  { appSessionIdForApp1, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("App2 SubscribeVehicleData custom_vd_item1_integer", common.VDsubscriptionWithoutReqOnHMI,
  { appSessionIdForApp2, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("App1 SubscribeVehicleData custom_vd_item2_float", common.VDsubscription,
  { appSessionIdForApp1, "custom_vd_item2_float", "SubscribeVehicleData" })

runner.Title("Test")
runner.Step("App1 and App2 OnVehicleData custom_vd_item1_integer", common.onVD2Apps, { "custom_vd_item1_integer"})
runner.Step("App1 OnVehicleData custom_vd_item2_float", common.onVD,
  { appSessionIdForApp1, "custom_vd_item2_float" })
runner.Step("App1 UnsubscribeVehicleData custom_vd_item1_integer, custom_vd_item2_float",
  processingVDunsubscribeWithSeveralData)
runner.Step("App2 OnVehicleData custom_vd_item1_integer", common.onVD2Apps,
  { "custom_vd_item1_integer", common.VD.NOT_EXPECTED, common.VD.EXPECTED })
runner.Step("App2 OnVehicleData custom_vd_item2_float", common.onVD,
  { appSessionIdForApp2, "custom_vd_item2_float", common.VD.NOT_EXPECTED })
runner.Step("App2 UnsubscribeVehicleData custom_vd_item1_integer", common.VDsubscription,
  { appSessionIdForApp2, "custom_vd_item1_integer", "UnsubscribeVehicleData" })
runner.Step("OnVehicleData is not resend custom_vd_item1_integer", common.onVD2Apps,
  { "custom_vd_item1_integer", common.VD.NOT_EXPECTED, common.VD.NOT_EXPECTED })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
