---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Processing GetVD/SubscribeVD/OnVD RPC's in case message(request or notification) contains undefined vehicle data

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VD from VehicleDataItems are defined in parameters of functional group

-- Sequence:
-- 1. GetVD/SubscribeVD with some_undefined_VD(data are not exist in VehicleDataItems) is requested from mobile app
--   b. SDL sends response(INVALID_DATA) to mobile app
-- 3. HMI sends OnVD notification with some_undefined_VD(data are not exist in VehicleDataItems)
--   a. SDL does not send the OnVD notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

--[[ Local Functions ]]
local function requestWithUndefinedData(pRPC)
  local mobRequestData = { ["some_undefined_data"] = true }
  local cid = common.getMobileSession():SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC)
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

local function onVD()
  local HMInotifData = { UNDEFINED_KEY = 100 }

  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", HMInotifData)

  common.getMobileSession():ExpectNotification("OnVehicleData")
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
runner.Step("GetVehicleData INVALID_DATA", requestWithUndefinedData, { "GetVehicleData" })
runner.Step("SubscribeVehicleData INVALID_DATA", requestWithUndefinedData, { "SubscribeVehicleData" })
runner.Step("OnVehicleData not expected", onVD)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
