---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying of the VehicleDataItems from PTU

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. Status of PTU is UPDATE_NEEDED
-- 4. PTU is triggered

-- Sequence:
-- 1. Mobile app receives the update with VehicleDataItems and provides it to SDL
--   a. SDL applies the update, saves it to DB
--   b. SDL sends OnPermissionChange with VehicleData according to update to mobile app
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
local function registerApp()
  common.getMobileSession():StartService(7)
  :Do(function()
      local corId = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams().appName } })
      :Do(function(_, d1)
          common.setHMIAppId(d1.params.application.appID, 1)
          common.isPTUStarted()
        end)
      common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
          :ValidIf(function(_, data)
            local _, params = common.getCustomAndRpcSpecDataNames()
            return common.onPermissionChangeValidation(data.payload.permissionItem, params)
          end)
        end)
    end)
end

local function checkPolicySnapshot()
  local preloadedTable = common.getPreloadedFileAndContent()
  local vehicleDataSchemaVersion = preloadedTable.policy_table.vehicle_data.schema_version
  local snapshotTbl = common.getPTS()
  if snapshotTbl ~= nil then
    if snapshotTbl.policy_table.vehicle_data then
      local isError = false
      local msg = ""
      if snapshotTbl.policy_table.vehicle_data.schema_items then
        isError = true
        msg = msg .. "snapshot file contains unexpected schema_items\n"
      end
      if snapshotTbl.policy_table.vehicle_data.schema_version then
        if  snapshotTbl.policy_table.vehicle_data.schema_version ~= vehicleDataSchemaVersion then
          isError = true
          msg = msg .. "schema_version had not expected value in snapshot.\n" ..
          "Expected value " .. vehicleDataSchemaVersion .. ".\n" ..
          "Actual value " .. snapshotTbl.policy_table.vehicle_data.schema_version .. ".\n"
        end
      else
        isError = true
        msg = msg .. "schema_version is not existed in snapshot file\n"
      end
      if isError == true then
        common:FailTestCase(msg)
      end
    else
      common:FailTestCase("vehicle_data is not existed in snapshot file")
    end

  else
    common:FailTestCase("snapshot file is not created")
  end
end

local function ptuWithOnPermissionChange()
  common.policyTableUpdate(common.ptuFuncWithCustomData)
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_, data)
      return common.onPermissionChangeValidation(data.payload.permissionItem, common.getAllVehicleData())
    end)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", registerApp)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Check VehicleDataItems in snapshot file", checkPolicySnapshot)
runner.Step("PTU with VehicleDataItems", ptuWithOnPermissionChange)
for vehicleDataName in pairs(common.VehicleDataItemsWithData) do
  if vehicleDataName == "vin" then
    runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD,
    { appSessionId, vehicleDataName })
  else
    runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
      { appSessionId, vehicleDataName, "SubscribeVehicleData" })
    runner.Step("OnVehicleData " .. vehicleDataName, common.onVD,
      { appSessionId, vehicleDataName })
    runner.Step("GetVehicleData " .. vehicleDataName, common.GetVD,
      { appSessionId, vehicleDataName })
    runner.Step("UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
      { appSessionId, vehicleDataName, "UnsubscribeVehicleData" })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
