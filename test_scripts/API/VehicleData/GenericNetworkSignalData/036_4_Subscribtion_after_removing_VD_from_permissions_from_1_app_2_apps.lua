---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing VD subscription in case when app is subscribed to custom data_1, data_2 and
-- app2 is subscribed for RPC spec data_3 after PTU is performed with removing of data_1

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group
-- 6. App1 is subscribed to custom data_1, data_2
-- 7. App2 is subscribed to RPC spec data_3

-- Sequence:
-- 1. PTU is triggered and performed with removed data_1 from VehicleDataItems
--   a. SDL sends VI.Unsubscribe(data_1) to HMI
-- 2. HMI sends OnVD(data_1) notification
--   a. SDL does not resend the OnVD notification to mobile app1
-- 3. HMI sends OnVD(data_2) notification
--   a. SDL resends the OnVD notification to mobile app1
-- 4. HMI sends OnVD(data_3) notification
--   a. SDL resends the OnVD notification to mobile app2
-- 5. Mobile app1 requests SubscribeVehicleData(data_1)
--   a. SDL rejects requests with INVALID_DATA resultCode
-- 6. Ignition off is performed
-- 7. Ignition on is performed
-- 8. Mobile app1 is registered and resumes the subscription for data_2
-- 9. Mobile app2 is registered and resumes the subscription for data_3
-- 10. HMI sends OnVD(data_1) notification
--   a. SDL does not resend the OnVD notification to mobile app1
-- 11. HMI sends OnVD(data_2) notification
--   a. SDL resends the OnVD notification to mobile app1
-- 12. HMI sends OnVD(data_3) notification
--   a. SDL resends the OnVD notification to mobile app2
-- 13. Mobile app1 requests SubscribeVehicleData(data_1)
--   a. SDL rejects requests with INVALID_DATA resultCode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId1 = 1
local appSessionId2 = 2
local itemToRemove = "custom_vd_item1_integer"
local customVDapp1 = "custom_vd_item2_float"
local rpcSpecDataApp2 = "gps"
local hashIDs = {}

--[[ Local Functions ]]
local function ptuFunc(pTbl)
  common.ptuFuncWithCustomData2Apps(pTbl)
  for key, item in pairs(pTbl.policy_table.vehicle_data.schema_items) do
    if item.name == itemToRemove then
      table.remove(pTbl.policy_table.vehicle_data.schema_items, key)
    end
  end
end

local function getParamsListForOnPermChange()
  local out = common.getAllVehicleData()
  for k,v in pairs(out) do
    if v == itemToRemove then
      table.remove(out, k)
    end
  end
  return out
end

local function expectFunc()
  local itemToRemoveKey =  common.VehicleDataItemsWithData[itemToRemove].key
  local expectedRequest = { [itemToRemoveKey] = true }
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {[itemToRemoveKey] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }})
  end)
  :ValidIf(function(_, data)
    return common.validation(data.params, expectedRequest, "VehicleInfo.UnsubscribeVehicleData")
  end)
end

local function registerApp1WithResumption()
  local itemKey =  common.VehicleDataItemsWithData[customVDapp1].key
  local expectedRequest = { [itemKey] = true }
  common.getConfigAppParams(appSessionId1).hashID = hashIDs[appSessionId1]
  common.registerAppWOPTU(appSessionId1)

  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {[itemKey] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }})
  end)
  :ValidIf(function(_, data)
    return common.validation(data.params, expectedRequest, "VehicleInfo.SubscribeVehicleData")
  end)
end

local function registerApp2WithResumption()
  local expectedRequest = { [rpcSpecDataApp2] = true,  }
  common.getConfigAppParams(appSessionId2).hashID = hashIDs[appSessionId2]
  common.registerAppWOPTU(appSessionId2)

  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
      [rpcSpecDataApp2] = {
        dataType = common.VehicleDataItemsWithData[rpcSpecDataApp2].APItype,
        resultCode = "SUCCESS"
      }
    })
  end)
  :ValidIf(function(_, data)
    return common.validation(data.params, expectedRequest, "VehicleInfo.SubscribeVehicleData")
  end)
end

local function saveHashId(pAppId)
  hashIDs[pAppId] = common.hashId
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Set ApplicationListUpdateTimeout=4000", common.setSDLIniParameter,
  { "ApplicationListUpdateTimeout", 4000 })
runner.Step("App1 registration", common.registerAppWOPTU, {appSessionId1})
runner.Step("App2 registration", common.registerAppWOPTU, {appSessionId2})
runner.Step("PTU with VehicleDataItems", common.ptuWithPolicyUpdateReq,
  { common.ptuFuncWithCustomData2Apps })
runner.Step("App1 activation", common.activateApp, {appSessionId1})
runner.Step("App2 activation", common.activateApp, {appSessionId2})

runner.Title("Test")
runner.Step("App1 SubscribeVehicleData " .. itemToRemove, common.VDsubscription,
  { appSessionId1, itemToRemove, "SubscribeVehicleData" })
runner.Step("App1 SubscribeVehicleData " .. customVDapp1, common.VDsubscription,
  { appSessionId1, customVDapp1, "SubscribeVehicleData" })
runner.Step("Save hashID for App1", saveHashId, {appSessionId1})
runner.Step("App2 SubscribeVehicleData " .. rpcSpecDataApp2, common.VDsubscription,
  { appSessionId2, rpcSpecDataApp2, "SubscribeVehicleData" })
runner.Step("Save hashID for App1", saveHashId, {appSessionId2})
runner.Step("App1 OnVehicleData " .. customVDapp1, common.onVD,
  { appSessionId1, customVDapp1 })
runner.Step("App2 OnVehicleData " .. rpcSpecDataApp2, common.onVD,
  { appSessionId2, rpcSpecDataApp2 })
runner.Step("App1 OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId1, itemToRemove })
runner.Step("PTU with removing " .. itemToRemove .. " from VehicleDataItems", common.ptuWithOnPolicyUpdateFromHMI,
  { ptuFunc, getParamsListForOnPermChange(), expectFunc })
runner.Step("App1 OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId1, itemToRemove, common.VD.NOT_EXPECTED })
runner.Step("App1 OnVehicleData " .. customVDapp1, common.onVD,
  { appSessionId1, customVDapp1 })
runner.Step("App2 OnVehicleData " .. rpcSpecDataApp2, common.onVD,
  { appSessionId2, rpcSpecDataApp2 })
runner.Step("App1 SubscribeVehicleData " .. itemToRemove .. " after VD was removed", common.errorRPCprocessing,
  { appSessionId1, itemToRemove, "SubscribeVehicleData", "INVALID_DATA" })

runner.Step("Exit apps", common.exitApps)
runner.Step("Ignition off", common.ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration after ign_off", registerApp1WithResumption)
runner.Step("App2 registration after ign_off", registerApp2WithResumption)
runner.Step("App1 activation after ign_off", common.activateApp, { appSessionId1 })
runner.Step("App2 activation after ign_off", common.activateApp, { appSessionId2 })

runner.Step("App1 OnVehicleData " .. itemToRemove, common.onVD,
  { appSessionId1, itemToRemove, common.VD.NOT_EXPECTED })
runner.Step("App1 OnVehicleData " .. customVDapp1, common.onVD,
  { appSessionId1, customVDapp1 })
runner.Step("App2 OnVehicleData " .. rpcSpecDataApp2, common.onVD,
  { appSessionId2, rpcSpecDataApp2 })
runner.Step("App1 SubscribeVehicleData " .. itemToRemove .. " after VD was removed", common.errorRPCprocessing,
  { appSessionId1, itemToRemove, "SubscribeVehicleData", "INVALID_DATA" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
