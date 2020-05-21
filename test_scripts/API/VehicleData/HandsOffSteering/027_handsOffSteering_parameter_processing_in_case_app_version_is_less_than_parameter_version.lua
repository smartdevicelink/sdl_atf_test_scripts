---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects vehicle data RPCs with 'handsOffSteering'
-- parameter if an app registered with version less than current parameter version
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Vehicle data RPCs and handsOffSteering parameter are allowed by policies
-- 3) handsOffSteering parameter has since = 6.2
-- 4) App is registered with syncMsgVersion = 5.0
--
-- In case:
-- 1) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = "INVALID_DATA") to App
-- - b) not transfer this request to HMI
-- 2) App send valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = "INVALID_DATA") to App
-- - b) not transfer this request to HMI
-- 3) App send valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "INVALID_DATA") to App
-- - b) not transfer this request to HMI
-- 4) HMI sends valid VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) ignored this notification and not transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Test Configuration ]]
common.getAppParams().syncMsgVersion.majorVersion = 5
common.getAppParams().syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local rpc_get = "GetVehicleData"
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local result = "INVALID_DATA"
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("RPC GetVehicleData with handsOffSteering parameter", common.processRPCFailure, { rpc_get, result })
common.Step("RPC " .. rpc_sub .. " with handsOffSteering parameter", common.processRPCFailure, { rpc_sub, result })
common.Step("Notification OnVehicleData with handsOffSteering parameter", common.sendOnVehicleData, { notExpected })
common.Step("RPC " .. rpc_unsub .. " with handsOffSteering parameter", common.processRPCFailure, { rpc_unsub, result })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
