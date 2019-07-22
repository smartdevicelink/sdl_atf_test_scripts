---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description:Processing VD requests with child items

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData are allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VehicleData from VehicleDataItems are defined in parameters of functional group for application

-- Sequence:
-- 1. SubscribeVD/UnsubscribeVD/GetVD is requested from mobile app with childName = true
--   a. SDL rejects request with resultCode INVALID_DATA
-- 2. HMI sends onVehicleData notification with child item as root one
--   a. SDL considers such notification ad invalid and does not resent it to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local paramsToCheck = { "struct_element_1_int", "longitudeDegrees" }

--[[ Local Functions ]]
local function errorRPCprocessing(pRequestData, pRPC)
  local mobRequestData = { [pRequestData] = true }
  local cid = common.getMobileSession():SendRPC(pRPC, mobRequestData)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC)
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

local function onVD(pData)
  local HMInotifData
  if pData == "struct_element_1_int" then
    HMInotifData = { ["OEM_REF_STRUCT_1_INT"] = 10 }
  else
    HMInotifData = { ["longitudeDegrees"] = 100 }
  end

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
for _, VDdata in pairs(paramsToCheck) do
  runner.Step("GetVehicleData " .. VDdata, errorRPCprocessing, { VDdata, "GetVehicleData" })
  runner.Step("SubscribeVehicleData " .. VDdata, errorRPCprocessing, { VDdata, "SubscribeVehicleData" })
  runner.Step("UnsubscribeVehicleData " .. VDdata, errorRPCprocessing, { VDdata, "UnsubscribeVehicleData" })
  runner.Step("OnVehicleData " .. VDdata, onVD, { VDdata })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
