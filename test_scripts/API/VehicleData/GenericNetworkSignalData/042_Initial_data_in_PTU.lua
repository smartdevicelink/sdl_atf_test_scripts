---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL ignores the update for RPC spec VD in PTU and does not fail the PTU

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. RPC spec VehicleData is allowed by policies
-- 3. App is registered and activated

-- Sequence:
-- 1. PTU is performed with VehicleDataItems that contains update for RPC spec data items
--   a. SDL does not apply the update for RPC spec data and applies the update for custom data
-- 2. VD from VehicleDataItems are defined in parameters of functional group
-- 3. SDL is subscribed for VDI
-- 4. HMI sends OnVD notification with values according to update for custom data and according to API for RPC spec data
--   a. SDL resends the OnVD notification to mobile app
-- 5. GetVD with VD from VehicleDataItems is requested from mobile app
--   a. SDL sends VI.GetVD with VD_name for RPC spec data and with VD_key for custom data to HMI
-- 6. HMI responds with successful response with VD_name for RPC spec data and with VD_key for custom data,
--   with values according to update for custom data and according to API for RPC spec data to SDL
--   a. SDL processes successful response from HMI
--   b. SDL converts VD_keys to VD_names for mobile response
--   c. SDL sends successful response with VD_name for RPC spec and custom data to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
common.writeCustomDataToGeneralArray(common.customDataTypeSample)

--[[ Local Variables ]]
local function addRpcSpecDataToUpdate()
  local rpcSpecData = {
    -- minvalue and maxvalue are updated
    {
      name = "rpm",
      type = "Integer",
      key =  "OEM_REF_RPM",
      array = false,
      mandatory = false,
      minvalue = 20001,
      maxvalue = 50000
    },
    -- updated type
    {
      name =  "headLampStatus",
      type = "Float",
      key = "OEM_REF_HLSTATUS",
      mandatory = false
    },
    -- updated mandatory
    {
        name = "engineTorque",
        type = "Float",
        key = "OEM_REF_ENG_TOR",
        mandatory = true
    },
    -- updated child params
    {
      name = "gps",
      type = "Struct",
      key = "OEM_REF_GPS",
      mandatory = false,
      maxsize = 100,
      params = {
          {
              name =  "speed",
              type = "Float",
              key = "OEM_REF_SPEED",
              mandatory = false
          }
      }
    }
  }

  for _, item in pairs(rpcSpecData) do
    table.insert(common.customDataTypeSample,item)
  end
end

addRpcSpecDataToUpdate()
common.setDefaultValuesForCustomData()

local appSessionId = 1

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
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
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
