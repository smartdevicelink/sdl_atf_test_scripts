---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes vehicle data RPCs with 'handsOffSteering'
-- parameter if an app is registered with version greater than current parameter version
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Vehicle data RPCs and handsOffSteering parameter are allowed by policies
-- 3) handsOffSteering parameter has since = 6.0
-- 4) App is registered with syncMsgVersion = 7.0
--
-- In case:
-- 1) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends VehicleInfo.GetVehicleData response with handsOffSteering data to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = "SUCCESS",
--    handsOffSteering = <data received from HMI>) to App
-- 3) App send valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 4) HMI sends VehicleInfo.SubscribeVehicleData response with handsOffSteering data to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
-- handsOffSteering = <data received from HMI>) to App
-- 5) HMI sends valid VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) transfer this notification to App
-- 6) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 7) HMI sends VehicleInfo.UnsubscribeVehicleData response with handsOffSteering data to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
-- handsOffSteering = <data received from HMI>) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Test Configuration ]]
common.getAppParams().syncMsgVersion.majorVersion = 7
common.getAppParams().syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("RPC GetVehicleData with handsOffSteering parameter", common.getVehicleData)
common.Step("RPC " .. rpc_sub .. " with handsOffSteering parameter", common.processSubscriptionRPC, { rpc_sub })
common.Step("Notification OnVehicleData with handsOffSteering parameter", common.sendOnVehicleData)
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter", common.processSubscriptionRPC, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
