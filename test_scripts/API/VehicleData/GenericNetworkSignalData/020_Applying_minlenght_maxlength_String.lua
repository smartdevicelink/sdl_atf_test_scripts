---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Applying of the minlength and maxlength for String VD type

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered and activated
-- 3. PTU is performed, the update contains the custom VD items in VehicleDataItems with type=String and
--   minlength, maxlength
-- 4. Custom VD is allowed
-- 5. App is subscribed for custom VD

-- Sequence:
-- 1. HMI sends OnVD with string length in range for custom VD
--   a. SDL resends OnVD notification to mobile app
-- 2. HMI sends OnVD with string length out of range for custom VD
--   a. SDL does not send OnVD to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
for VDkey, VDitem in pairs (common.customDataTypeSample)do
  if VDitem.name == "custom_vd_item11_struct" then
    for subVDkey, subVDitem in pairs(VDitem.params) do
      if subVDitem.name == "struct_element_2_str" then
        common.customDataTypeSample[VDkey].params[subVDkey].minlength = 3
        common.customDataTypeSample[VDkey].params[subVDkey].maxlength = 7
      end
    end
  end
end

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId = 1
local onVDNOTexpected = 0
local paramsForChecking = { "custom_vd_item4_string", "custom_vd_item11_struct" }
local string256symb = string.rep("a", 256)

--[[ Local Functions ]]
local function setNewIntParams(pValueRootLevel, pVelueChildLevel)
  common.VehicleDataItemsWithData.custom_vd_item4_string.value = pValueRootLevel
  common.VehicleDataItemsWithData.custom_vd_item11_struct.params.struct_element_2_str.value = pVelueChildLevel
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

runner.Step("Update parameter values to minvalue", setNewIntParams, { "a", "abc" })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData minvalue " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to maxvalue", setNewIntParams, { string256symb, "abcdefg" })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData maxvalue " .. vehicleDataName, common.onVD, { appSessionId, vehicleDataName })
end

runner.Step("Update parameter values to out of minvalue", setNewIntParams, { "", "ab" })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData out of minvalue " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, onVDNOTexpected })
end

runner.Step("Update parameter values to out of maxvalue", setNewIntParams, { string256symb .. "a", "abcdefgh" })
for _, vehicleDataName in pairs(paramsForChecking) do
  runner.Step("OnVehicleData out of maxvalue " .. vehicleDataName, common.onVD,
    { appSessionId, vehicleDataName, onVDNOTexpected })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
