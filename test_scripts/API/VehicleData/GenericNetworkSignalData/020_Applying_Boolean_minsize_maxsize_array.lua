---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying of the minsize and maxsize for array of VD with type=Bool

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains the custom VD items in VehicleDataItems with type=Boolean, array=true,
--   minsize and maxsize
-- 4. Custom VD is allowed
-- 5. App is subscribed for custom VD

-- Sequence:
-- 1. HMI sends OnVD with array size and element value in range for custom VD
--   a. SDL resends OnVD notification to mobile app
-- 2. HMI sends OnVD with array size out of range for custom VD
--   a. SDL does not send OnVD to mobile app
-- ---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1
local paramsForChecking = { "custom_vd_item10_array_bool" }
local arrayMinSize = common.EMPTY_ARRAY

-- parameter values for root element
local rootArrayMaxSize = { }
for i=1,common.VehicleDataItemsWithData.custom_vd_item10_array_bool.maxsize do
  rootArrayMaxSize[i] = false
end

local rootArrayOutOfMaxSize = common.cloneTable(rootArrayMaxSize)
table.insert(rootArrayOutOfMaxSize, true)

--[[ Local Functions ]]
local function setNewArrayValues(pValueRootLevel)
  common.VehicleDataItemsWithData.custom_vd_item10_array_bool.value = pValueRootLevel
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.policyTableUpdateWithOnPermChange, { common.ptuFuncWithCustomData })

runner.Title("Test")
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
    { appSessionId, vehicleDataName, "SubscribeVehicleData" })
end

runner.Step("Update parameter values to minsize", setNewArrayValues, { arrayMinSize })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData minsize " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to maxsize", setNewArrayValues, { rootArrayMaxSize })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData maxsize " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to out of maxsize", setNewArrayValues, { rootArrayOutOfMaxSize })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData out of maxsize " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, common.VD.NOT_EXPECTED })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
