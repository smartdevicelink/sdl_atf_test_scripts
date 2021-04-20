---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL applies since, until parameters for custom VehicleData

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App1 is registered with majorVersion = 3.0
-- 3. App2 is registered with majorVersion = 5.9
-- 4. PTU is performed, the update contains single VehicleDataItems with since, until parameters
-- 5. Custom VD is allowed

-- Sequence:
-- 1. SubscribeVD/GetVD/UnsubscribeVD with custom VD is requested from mobile app
--   a. SDL applies since, until parameters
--   b. SDL processes the requests according to defined since, until parameters in update
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 3
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 9

--[[ Local Variables ]]
local itemInteger
local vehicleDataName = "custom_vd_item1_integer"
local validVDvalueForApp1 = 50
local validVDvalueForApp2 = 150

for VDkey, VDitem in pairs (common.customDataTypeSample)do
  if VDitem.name == vehicleDataName then
    itemInteger = common.cloneTable(common.customDataTypeSample[VDkey])
    common.customDataTypeSample[VDkey]["since"] = "1.0"
    common.customDataTypeSample[VDkey]["until"] = "5.0"
    itemInteger.minvalue = 101
    itemInteger.maxvalue = 1000
    itemInteger.since = "5.0"
  end
end

table.insert(common.customDataTypeSample, itemInteger)

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId1 = 1
local appSessionId2 = 2

local function setNewParams()
  common.VehicleDataItemsWithData[vehicleDataName].value = validVDvalueForApp2
end

local function getVehicleDataGenericError(pAppId, pData)
  local mobRequestData = { [common.VehicleDataItemsWithData[pData].name] = true }
  local hmiRequestData = common.getHMIrequestData(pData)
  local hmiResponseData = common.getVehicleDataResponse(pData)
  local cid = common.getMobileSession(pAppId):SendRPC("GetVehicleData", mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

local function onVD2AppsWithDifferentValues()
  common.VehicleDataItemsWithData[vehicleDataName].value = validVDvalueForApp1
  local HMInotifData1 = common.getVehicleDataResponse(vehicleDataName)
  common.VehicleDataItemsWithData[vehicleDataName].value = validVDvalueForApp2
  local HMInotifData2, mobileNotifData2 = common.getVehicleDataResponse(vehicleDataName)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", HMInotifData1)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", HMInotifData2)

  common.getMobileSession(1):ExpectNotification("OnVehicleData", mobileNotifData2)
  common.getMobileSession(2):ExpectNotification("OnVehicleData", mobileNotifData2)

  common.wait(500)
end

local function subscriptionFor2Apps()
  local vehicleData = common.VehicleDataItemsWithData[vehicleDataName]
  local mobileRequest = { [vehicleDataName] = true }
  local hmiRequestData = common.getHMIrequestData(vehicleDataName)
  local hmiResponseData = {
    [vehicleData.key] = {
      dataType = common.CUSTOM_DATA_TYPE,
      resultCode = "SUCCESS"
    }
  }

  local cid1 = common.getMobileSession(1):SendRPC("SubscribeVehicleData", mobileRequest)
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", hmiRequestData)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseData)
  end)

  local mobileResponseData = { [vehicleDataName] = common.cloneTable(hmiResponseData[vehicleData.key]) }
  mobileResponseData[vehicleDataName].oemCustomDataType = vehicleData.type
  mobileResponseData.success = true
  mobileResponseData.resultCode = "SUCCESS"
  common.getMobileSession(1):ExpectResponse(cid1, mobileResponseData)
  :ValidIf(function(_,data)
    return common.validation(data.payload, mobileResponseData, "SubscribeVehicleData response")
  end)
  :Do(function()
    local cid2 = common.getMobileSession(2):SendRPC("SubscribeVehicleData", mobileRequest)
    common.getMobileSession(2):ExpectResponse(cid2, mobileResponseData)
    :ValidIf(function(_,data)
      return common.validation(data.payload, mobileResponseData, "SubscribeVehicleData response")
    end)
  end)

  common.getMobileSession(1):ExpectNotification("OnHashChange")
  common.getMobileSession(2):ExpectNotification("OnHashChange")
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ApplicationListUpdateTimeout=4000", common.setSDLIniParameter,
  { "ApplicationListUpdateTimeout", 4000 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerAppWOPTU, { appSessionId1 })
runner.Step("App2 registration", common.registerAppWOPTU, { appSessionId2 })
runner.Step("App1 activation", common.activateApp, { appSessionId1 })
runner.Step("PTU with VehicleDataItems", common.ptuWithPolicyUpdateReq, { common.ptuFuncWithCustomData2Apps })
runner.Step("App2 activation", common.activateApp, { appSessionId2 })

runner.Title("Test")
runner.Step("App1 SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
  { appSessionId1, vehicleDataName, "SubscribeVehicleData" })
runner.Step("App1 OnVehicleData " .. vehicleDataName, common.onVD,
  { appSessionId1, vehicleDataName, common.VD.NOT_EXPECTED })
runner.Step("App1 UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
  { appSessionId1, vehicleDataName, "UnsubscribeVehicleData" })
runner.Step("App1 GetVehicleData " .. vehicleDataName, getVehicleDataGenericError, { appSessionId1, vehicleDataName })

runner.Step("App2 SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
  { appSessionId2, vehicleDataName, "SubscribeVehicleData" })
runner.Step("App2 OnVehicleData " .. vehicleDataName, common.onVD,
  { appSessionId2, vehicleDataName, common.VD.NOT_EXPECTED })
runner.Step("App2 UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
  { appSessionId2, vehicleDataName, "UnsubscribeVehicleData" })
runner.Step("App2 GetVehicleData " .. vehicleDataName, getVehicleDataGenericError,
  { appSessionId2, vehicleDataName })

runner.Step("Update parameter values according to since and until values", setNewParams)
runner.Step("App2 SubscribeVehicleData " .. vehicleDataName .. " with updated values", common.VDsubscription,
  { appSessionId2, vehicleDataName, "SubscribeVehicleData" })
runner.Step("App2 OnVehicleData " .. vehicleDataName, common.onVD,
  { appSessionId2, vehicleDataName, common.VD.EXPECTED })
runner.Step("App2 UnsubscribeVehicleData " .. vehicleDataName .. " with updated values", common.VDsubscription,
  { appSessionId2, vehicleDataName, "UnsubscribeVehicleData" })
runner.Step("App2 GetVehicleData " .. vehicleDataName .. " with updated values", common.GetVD,
  { appSessionId2, vehicleDataName })

runner.Step("App1 SubscribeVehicleData " .. vehicleDataName .. " with updated values", common.VDsubscription,
  { appSessionId1, vehicleDataName, "SubscribeVehicleData" })
runner.Step("App1 OnVehicleData " .. vehicleDataName .. " with updated values", common.onVD,
  { appSessionId1, vehicleDataName, common.VD.EXPECTED })
runner.Step("App1 UnsubscribeVehicleData " .. vehicleDataName .. " with updated values", common.VDsubscription,
  { appSessionId1, vehicleDataName, "UnsubscribeVehicleData" })
runner.Step("App1 GetVehicleData " .. vehicleDataName .. " with updated values", common.GetVD,
  { appSessionId1, vehicleDataName })

runner.Step("SubscribeVehicleData for 2 apps " .. vehicleDataName, subscriptionFor2Apps)
runner.Step("Two apps onVehicleData " .. vehicleDataName, onVD2AppsWithDifferentValues)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
