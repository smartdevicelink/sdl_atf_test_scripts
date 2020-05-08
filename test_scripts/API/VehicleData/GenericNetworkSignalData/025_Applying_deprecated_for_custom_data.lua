---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL applies deprecated parameters for custom VehicleData

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App1 is registered with majorVersion = 3.0
-- 3. App2 is registered with majorVersion = 5.9
-- 4. PTU is performed, the update contains VehicleDataItems with deprecated parameter
-- 5. Custom VD is allowed

-- Sequence:
-- 1. SubscribeVD/GetVD/UnsubscribeVD with custom VD is requested from mobile app
--   a. SDL applies deprecated parameter
--   b. SDL processes the requests according to deprecated parameter in update
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 3
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 9

--[[ Local Variables ]]
local itemBool

for VDkey, VDitem in pairs (common.customDataTypeSample)do
  if VDitem.name == "custom_vd_item5_boolean" then
    itemBool = common.cloneTable(common.customDataTypeSample[VDkey])
    common.customDataTypeSample[VDkey]["since"] = "1.0"
    common.customDataTypeSample[VDkey]["until"] = "5.0"
    itemBool.deprecated = true
    itemBool.since = "5.0"
  elseif VDitem.name == "custom_vd_item6_array_string" then
    common.customDataTypeSample[VDkey].deprecated = false
  end
end

table.insert(common.customDataTypeSample, itemBool)

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId1 = 1
local appSessionId2 = 2

local paramsWithUpdatedProps = { "custom_vd_item5_boolean", "custom_vd_item6_array_string" }

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ApplicationListUpdateTimeout=4000", common.setSDLIniParameter,
  { "ApplicationListUpdateTimeout", 4000 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerAppWOPTU, { appSessionId1 })
runner.Step("App2 registration", common.registerAppWOPTU, { appSessionId2 })
runner.Step("App1 activation", common.activateApp, { appSessionId1 })
runner.Step("PTU with VehicleDataItems", common.ptuWithPolicyUpdateReq, { common.ptuFuncWithCustomData2Apps })
runner.Step("App2 activation", common.activateApp, { appSessionId2 })

runner.Title("Test")
for _, vehicleDataName in pairs(paramsWithUpdatedProps) do
  for i=1,2 do
    runner.Step("App" .. i .." SubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
      { i, vehicleDataName, "SubscribeVehicleData" })
    runner.Step("App" .. i .." OnVehicleData " .. vehicleDataName, common.onVD, { i, vehicleDataName })
    runner.Step("App" .. i .." UnsubscribeVehicleData " .. vehicleDataName, common.VDsubscription,
      { i, vehicleDataName, "UnsubscribeVehicleData" })
    runner.Step("App" .. i .." GetVehicleData " .. vehicleDataName, common.GetVD, { i, vehicleDataName })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
