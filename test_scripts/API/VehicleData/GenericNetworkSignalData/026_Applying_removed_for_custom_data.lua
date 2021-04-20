---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL applies removed parameter for custom VehicleData

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App1 is registered with majorVersion = 3
-- 3. App2 is registered with majorVersion = 6
-- 4. PTU is performed, the update contains VehicleDataItems with removed parameter
-- 5. Custom VD is allowed

-- Sequence:
-- 1. SubscribeVD/GetVD/UnsubscribeVD with custom VD is requested from mobile app
--   a. SDL applies removed parameter
--   b. SDL processes the requests according to defined removed parameter in update
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 3
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local itemEnum

for VDkey, VDitem in pairs (common.customDataTypeSample)do
  if VDitem.name == "custom_vd_item3_enum" then
    itemEnum = common.cloneTable(common.customDataTypeSample[VDkey])
    common.customDataTypeSample[VDkey]["since"] = "1.0"
    common.customDataTypeSample[VDkey]["until"] = "5.0"
    itemEnum.removed = true
    itemEnum.since = "5.0"
  elseif VDitem.name == "custom_vd_item4_string" then
    common.customDataTypeSample[VDkey].removed = false
  end
end

table.insert(common.customDataTypeSample, itemEnum)

common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionId1 = 1
local appSessionId2 = 2

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
for i=1,2 do
  runner.Step("App" .. i .. " SubscribeVehicleData custom_vd_item4_string", common.VDsubscription,
    { i, "custom_vd_item4_string", "SubscribeVehicleData" })
  runner.Step("App" .. i .. " OnVehicleData custom_vd_item4_string", common.onVD, { i, "custom_vd_item4_string" })
  runner.Step("App" .. i .. " UnsubscribeVehicleData custom_vd_item4_string", common.VDsubscription,
    { i, "custom_vd_item4_string", "UnsubscribeVehicleData" })
  runner.Step("App" .. i .. " GetVehicleData custom_vd_item4_string", common.GetVD, { i, "custom_vd_item4_string" })
end

runner.Step("App1 SubscribeVehicleData custom_vd_item3_enum", common.VDsubscription,
  { appSessionId1, "custom_vd_item3_enum", "SubscribeVehicleData" })
runner.Step("App1 OnVehicleData custom_vd_item3_enum", common.onVD, { appSessionId1, "custom_vd_item3_enum" })
runner.Step("App1 UnsubscribeVehicleData custom_vd_item3_enum", common.VDsubscription,
  { appSessionId1, "custom_vd_item3_enum", "UnsubscribeVehicleData" })
runner.Step("App1 GetVehicleData custom_vd_item3_enum", common.GetVD, { appSessionId1, "custom_vd_item3_enum" })

runner.Step("App2 SubscribeVehicleData custom_vd_item3_enum", common.errorRPCprocessing,
  { appSessionId2, "custom_vd_item3_enum", "SubscribeVehicleData", "INVALID_DATA"})
runner.Step("App2 OnVehicleData custom_vd_item3_enum", common.onVD,
  { appSessionId2, "custom_vd_item3_enum", common.VD.NOT_EXPECTED })
runner.Step("App2 GetVehicleData custom_vd_item3_enum", common.errorRPCprocessing,
  { appSessionId2, "custom_vd_item3_enum", "GetVehicleData", "INVALID_DATA"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
