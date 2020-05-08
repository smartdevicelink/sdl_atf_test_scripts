---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing Subscribe/Unsubscribe RPC's in case data related to VDitems are invalid in mobile request

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group
-- 6. VD is subscribed ( for unsubscribe )

-- Sequence:
-- 1. SubscribeVD/UnsubscribeVD with invalid type of VD is requested from mobile app
--   a. SDL does not send VI.Unsubscribe/SubscribeVD to HMI
--   b. SDL sends response(INVALID_DATA) to mobile app
-- 2. HMI sends OnVD notification with VD
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
local function errorRPCprocessing(pData, pRPC)
  local mobRequestData = { [common.VehicleDataItemsWithData[pData].name] = "true" }
  local cid = common.getMobileSession():SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC)
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
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
  runner.Step("SubscribeVehicleData INVALID_DATA " .. vehicleDataName, errorRPCprocessing,
    { vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end
for _, vehicleDataName in pairs(paramsForCheckingForUnsubscribe) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName })
  runner.Step("UnsubscribeVehicleData INVALID_DATA " .. vehicleDataName, errorRPCprocessing,
    { vehicleDataName, "UnsubscribeVehicleData" })
  runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
