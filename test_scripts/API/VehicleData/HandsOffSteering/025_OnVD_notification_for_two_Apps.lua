---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes OnVehicleData notification with 'handsOffSteering' parameter for two Apps
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs OnVehicleData, SubscribeVehicleData notification and handsOffSteering parameter are allowed by policies
-- 3) App_1 and App_2 are registered
--
-- In case:
-- 1) HMI sends valid VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) not transfer this notification to both apps
-- 1) App_1 subscribes to handsOffSteering data
-- 2) HMI sends valid VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) transfer this notification only to App_1
-- 3) App_2 subscribes to handsOffSteering data
-- 4) HMI sends valid VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) transfer this notification to App_1 and App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local value = { true, false }
local rpc_sub = "SubscribeVehicleData"
local appId_1 = 1
local appId_2 = 2
local isExpectedSubscribeVDonHMI = true
local isNotExpectedSubscribeVDonHMI = false
local expected = 1
local notExpected = 0

--[[ Local Functions ]]
local function onVehicleDataForTwoApps(pHandsOffSteering, pExpTimesApp1, pExpTimesApp2)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = pHandsOffSteering })
  common.getMobileSession(appId_1):ExpectNotification("OnVehicleData", { handsOffSteering = pHandsOffSteering })
  :Times(pExpTimesApp1)
  common.getMobileSession(appId_2):ExpectNotification("OnVehicleData", { handsOffSteering = pHandsOffSteering })
  :Times(pExpTimesApp2)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerApp, { appId_1 })
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })

common.Title("Test")
for _, v in pairs(value) do
  common.Step("Absence OnVehicleData notification for both apps with handsOffSteering=" .. tostring(v),
    onVehicleDataForTwoApps, { v, notExpected, notExpected })
end
common.Step("App_1 subscribes to handsOffSteering data",
common.processSubscriptionRPC, { rpc_sub, appId_1, isExpectedSubscribeVDonHMI })
for _, v in pairs(value) do
  common.Step("OnVehicleData notification to App_1 with handsOffSteering=" .. tostring(v),
    onVehicleDataForTwoApps, { v, expected, notExpected })
end
common.Step("App_2 subscribes to handsOffSteering data",
  common.processSubscriptionRPC, { rpc_sub, appId_2, isNotExpectedSubscribeVDonHMI })
for _, v in pairs(value) do
  common.Step("OnVehicleData notification tp both apps with handsOffSteering=" .. tostring(v),
    onVehicleDataForTwoApps, { v, expected, expected })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
