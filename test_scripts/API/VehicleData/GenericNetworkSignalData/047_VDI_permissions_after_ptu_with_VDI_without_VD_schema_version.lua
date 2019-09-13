---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL does no apply any changes for VDI after PTU without schema_version

-- Precondition:
-- 1. sdl_preloaded_pt file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated
-- 4. PTU is performed with VehicleDataItems in update file
-- 5. VehicleData from VehicleDataItems are defined in parameters of functional group for application
-- 6. PTU is triggered from HMI

-- Sequence:
-- 1. PTU is performed with VehicleDataItems but without schema_version in update file
-- 2. SubscribeVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.SubscribeVD with VD_name for RPC spec data and with VD_key for custom data to HMI
--     as before last PTU
-- 3. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data to SDL
--   a. SDL processes successful response from HMI as before last PTU
--   b. SDL converts VD_keys to VD_names for mobile response as before last PTU
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app as before last PTU
-- 4. HMI sends OnVD notification with subscribed data
--   a. SDL resends the OnVD notification to mobile app as before last PTU
-- 5. GetVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.GetVD with VD_name for RPC spec data and with VD_key for custom data to HMI as before last PTU
-- 6. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data to SDL
--   a. SDL processes successful response from HMI as before last PTU
--   b. SDL converts VD_keys to VD_names for mobile response as before last PTU
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app as before last PTU
-- 7. UnsubscribeVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.UnsubscribeVD with VD_name for RPC spec data and with VD_key for custom data to HMI
--     as before last PTU
-- 8. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data to SDL
--   a. SDL processes successful response from HMI as before last PTU
--   b. SDL converts VD_keys to VD_names for mobile response as before last PTU
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app as before last PTU
-- 9. HMI sends OnVD notification with subscribed data
--   a. SDL does not send the OnVD notification to mobile app as before last PTU
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
local function ptuFunc(pTbl)
  common.ptuFuncWithCustomData(pTbl)
  pTbl.policy_table.vehicle_data.schema_version = nil
end

local function ExpNotificationFunc()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" })
  :Times(3)
end

local function ptuWithOnPolicyUpdateFromHMI(pPtuFunc, pExpNotificationFunc)
  pExpNotificationFunc()
  common.isPTUStarted()
  :Do(function()
    common.policyTableUpdateWithoutOnPermChange(pPtuFunc, function() end)
  end)
  common.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })
runner.Step("PTU without VehicleDataItems", ptuWithOnPolicyUpdateFromHMI, { ptuFunc, ExpNotificationFunc })

runner.Title("Test")
for _, vehicleDataItem in pairs(common.VehicleDataItemsWithData) do
  if vehicleDataItem.name == "vin" then
    runner.Step("GetVehicleData " .. vehicleDataItem.name, common.GetVD,
      { appSessionId, vehicleDataItem.name })
  else
    runner.Step("SubscribeVehicleData " .. vehicleDataItem.name, common.VDsubscription,
      { appSessionId, vehicleDataItem.name, "SubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataItem.name, common.onVD,
      { appSessionId, vehicleDataItem.name })
    runner.Step("GetVehicleData " .. vehicleDataItem.name, common.GetVD,
      { appSessionId, vehicleDataItem.name })
    runner.Step("UnsubscribeVehicleData " .. vehicleDataItem.name, common.VDsubscription,
      { appSessionId, vehicleDataItem.name, "UnsubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataItem.name, common.onVD,
      { appSessionId, vehicleDataItem.name, common.VD.NOT_EXPECTED })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
