---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: Cache of the subscription for RPC spec and custom VehicleDataItems with several apps
--
-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. VehicleData is allowed by policies
-- 3. 2 apps are registered
-- 4. App1 is activated
-- 5. PTU is performed with VehicleDataItems in update file
--
-- Sequence:
-- 1. SubscribeVD(data_1) is requested from mobile app1
--   a. SDL sends VI.SubscribeVD(data_1) to HMI
-- 2. HMI responds with successful response to SDL
--   a. SDL processes successful response from HMI
--   b. SDL sends successful response to mobile app1
-- 3. HMI sends OnVD(data_1) notification
--   a. SDL resends the OnVD notification to mobile app1
-- 4. App2 is activated
-- 5. SubscribeVD(data_1) is requested from mobile app2
--   a. SDL does not send VI.SubscribeVD to HMI
--   b. SDL sends successful response to mobile app2
-- 6. HMI sends OnVD(data_1) notification
--   a. SDL resends the OnVD notification to mobile app1 and mobile app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.writeCustomDataToGeneralArray(common.customDataTypeSample)
common.setDefaultValuesForCustomData()

local appSessionIdForApp1 = 1
local appSessionIdForApp2 = 2

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set ApplicationListUpdateTimeout=4000", common.setSDLIniParameter,
  { "ApplicationListUpdateTimeout", 4000 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerAppWOPTU)
runner.Step("App2 registration", common.registerAppWOPTU, { appSessionIdForApp2 })
runner.Step("App1 activation", common.activateApp)
runner.Step("PTU with VehicleDataItems", common.ptuWithPolicyUpdateReq, { common.ptuFuncWithCustomData2Apps })

runner.Title("Test")
runner.Step("App1 SubscribeVehicleData custom_vd_item1_integer", common.VDsubscription,
  { appSessionIdForApp1, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("App1 OnVehicleData custom_vd_item1_integer", common.onVD,
  { appSessionIdForApp1, "custom_vd_item1_integer" })
runner.Step("App2 activation", common.activateApp, { appSessionIdForApp2 })
runner.Step("App2 SubscribeVehicleData custom_vd_item1_integer", common.VDsubscriptionWithoutReqOnHMI,
  { appSessionIdForApp2, "custom_vd_item1_integer", "SubscribeVehicleData" })
runner.Step("App1 and App2 OnVehicleData custom_vd_item1_integer", common.onVD2Apps, { "custom_vd_item1_integer" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
