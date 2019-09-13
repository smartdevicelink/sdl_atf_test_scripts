---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL applies changes for VDI after PTU without custom_vehicle_data_mapping_url in endpoint_properties

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is started
-- 4. The update received from cloud without custom_vehicle_data_mapping_url in endpoint_properties

-- Sequence:
-- 1. Update is considered as valid
-- 2. Mobile app requests RPC with RPC spec data or custom data
--   a. SDL processes the request successfully
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
local function ptuFuncWithoutCustomUrl(pTbl)
  common.ptuFuncWithCustomData(pTbl)
  pTbl.policy_table.module_config.endpoint_properties = {
    some_data = { version = "10" }
  }
end

local function ptuFuncWithEmptyEndpointProperties(pTbl)
  common.ptuFuncWithCustomData(pTbl)
  pTbl.policy_table.module_config.endpoint_properties = common.EMPTY_OBJECT
end

local function policyTableUpdateWithoutOnPermChange(pPTUpdateFunc)
  common.isPTUStarted()
  :Do(function()
    common.policyTableUpdate(pPTUpdateFunc)
  end)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :Times(0)
  common.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with without custom_vehicle_data_mapping_url", common.policyTableUpdateWithOnPermChange, { ptuFuncWithoutCustomUrl })
runner.Step("PTU with empty endpoint_properties", policyTableUpdateWithoutOnPermChange,
  { ptuFuncWithEmptyEndpointProperties })

runner.Title("Test")
for vehicleDataItem in pairs(common.VehicleDataItemsWithData) do
  if vehicleDataItem == "vin" then
    runner.Step("GetVehicleData " .. vehicleDataItem, common.GetVD,
      { appSessionId, vehicleDataItem })
  else
    runner.Step("SubscribeVehicleData " .. vehicleDataItem, common.VDsubscription,
      { appSessionId, vehicleDataItem, "SubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataItem, common.onVD,
      { appSessionId, vehicleDataItem })
    runner.Step("GetVehicleData " .. vehicleDataItem, common.GetVD,
      { appSessionId, vehicleDataItem })
    runner.Step("UnsubscribeVehicleData " .. vehicleDataItem, common.VDsubscription,
      { appSessionId, vehicleDataItem, "UnsubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataItem, common.onVD,
      { appSessionId, vehicleDataItem, common.VD.NOT_EXPECTED })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
