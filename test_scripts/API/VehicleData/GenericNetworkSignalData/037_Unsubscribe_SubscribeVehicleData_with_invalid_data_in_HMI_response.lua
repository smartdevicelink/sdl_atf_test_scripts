---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing Subscribe/Unsubscribe RPC's in case data related to VDitems are invalid in HMI response

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group
-- 6. VD is subscribed ( for unsubscribe )

-- Sequence:
-- 1. Subscribe/UnsubscribeVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.Subscribe/UnsubscribeVD to HMI
-- 2. HMI responds with VD invalid data( vehileData = { unknown enum value } )
--   a. SDL processes response from HMI
--   b. SDL sends response(GENERIC_ERROR) to mobile app
-- 3. HMI sends OnVD notification with VD
--   a. SDL does not send/resends the OnVD notification to mobile app
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

local paramsForCheckingForSubscribe = { "gps", "custom_vd_item1_integer" }
local paramsForCheckingForUnsubscribe = { "rpm", "custom_vd_item2_float" }

--[[ Local Functions ]]
local function VDsubscription(pData, pRPC)
  local hmiReqResData
  local pVehicleData = common.VehicleDataItemsWithData[pData]
  if pVehicleData.rpcSpecData == true then
    hmiReqResData = pVehicleData.name
  else
    hmiReqResData = pVehicleData.key
  end

  local hmiRequestData
  if pRPC == "UnsubscribeVehicleData" and
    pVehicleData.rpcSpecData ~= true then
      hmiRequestData = { [pVehicleData.key] = true }
  elseif pRPC == "UnsubscribeVehicleData" then
    hmiRequestData = { [pVehicleData.name] = true }
  else
    hmiRequestData = common.getHMIrequestData(pData)
  end

  local mobRequestData = { [pVehicleData.name] = true }
  local hmiResponseData = {
    [hmiReqResData] = {
      dataType = "UNKNOWN_ENUM",
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

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
for _, vehicleDataName in pairs(paramsForCheckingForSubscribe) do
  runner.Step("SubscribeVehicleData GENERIC_ERROR " .. vehicleDataName, VDsubscription,
    { vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end
for _, vehicleDataName in pairs(paramsForCheckingForUnsubscribe) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName })
  runner.Step("UnsubscribeVehicleData GENERIC_ERROR " .. vehicleDataName, VDsubscription,
    { vehicleDataName, "UnsubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
