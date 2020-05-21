---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL restores the subscription to 'handsOffSteering' parameter after IGN_OFF/IGN_ON
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPC SubscribeVehicleData and handsOffSteering are allowed by policies
-- 3) App is registered and subscribed to handsOffSteering data
-- 4) IGN_OFF and IGN_ON are performed
--
-- In case:
-- 1) App re-registers with actual HashId
-- SDL does:
-- - a) send VehicleInfo.SubscribeVehicleData(handsOffSteering=true) request to HMI during resumption
-- - b) process successful response from HMI
-- - c) restore subscription for handsOffSteering data
-- - d) respond RAI(SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local appId = 1
local subscribeVDExpectedOnHMI = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering data", common.processSubscriptionRPC, { rpc })

common.Title("Test")
common.Step("IGNITION_OFF", common.ignitionOff)
common.Step("IGNITION_ON", common.start)
common.Step("Re-register App resumption data", common.registerAppWithResumption,
  { appId, subscribeVDExpectedOnHMI })
common.Step("Check resumption of subscription using OnVehicleData notification",
  common.sendOnVehicleData)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
