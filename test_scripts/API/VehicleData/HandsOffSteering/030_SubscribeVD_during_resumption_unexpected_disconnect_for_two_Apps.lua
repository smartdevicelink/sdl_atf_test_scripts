---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL restores SubscribeVehicleData on 'handsOffSteering' parameter after unexpected disconnect
-- for two apps
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPC SubscribeVehicleData and handsOffSteering are allowed by policies
-- 3) App_1 and App_2 are registered and subscribed to handsOffSteering data
-- 4) Unexpected disconnect and reconnect are performed
--
-- In case:
-- 1) App_1 re-registers with actual HashId
-- SDL does:
-- - a) send VehicleInfo.SubscribeVehicleData(handsOffSteering=true) request to HMI during resumption
-- - b) process successful response from HMI
-- - c) restore subscription for handsOffSteering data
-- - d) respond RAI(SUCCESS) to mobile app
-- 2) App_2 re-registers with actual HashId
-- SDL does:
-- - a) not send VehicleInfo.SubscribeVehicleData request to HMI during resumption
-- - b) restore subscription for handsOffSteering data internally
-- - c) respond RAI(SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local appId_1 = 1
local appId_2 = 2
local isExpectedSubscribeVDonHMI = true
local isNotExpectedSubscribeVDonHMI = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerApp, { appId_1 })
common.Step("App_1 subscribes to handsOffSteering data",
  common.processSubscriptionRPC, { rpc_sub, appId_1, isExpectedSubscribeVDonHMI })
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })
common.Step("App_2 subscribes to handsOffSteering data",
  common.processSubscriptionRPC, { rpc_sub, appId_2, isNotExpectedSubscribeVDonHMI })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App_1 with data resumption",
  common.registerAppWithResumption, { appId_1, isExpectedSubscribeVDonHMI })
common.Step("Check resumption data OnVehicleData notification", common.sendOnVehicleData)
common.Step("Re-register App_2 with data resumption",
  common.registerAppWithResumption, { appId_2, isNotExpectedSubscribeVDonHMI })
common.Step("Check resumption data OnVehicleData notification with handsOffSteering parameter for two Apps",
  common.onVehicleDataTwoApps)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
