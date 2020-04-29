---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL resumes the subscription for 'windowStatus' parameter for two Apps after IGN_OFF/ON.
--
-- Precondition:
-- 1) Two apps are registered and activated.
-- 2) Apps are subscribed to `windowStatus` data.
-- 3) IGN_OFF and IGN_ON are performed.
-- In case:
-- 1) App_1 registers with actual hashID
-- SDL does:
--  a) start data resumption for app
--  b) start to resume the subscription and sends VI.SubscribeVD request to HMI
--  c) after success response from HMI SDL resumes the subscription
-- 2 App_2 registers with actual hashID
-- SDL does:
--  a) start data resumption for app
--  b) resume the subscription internally and Not send VI.SubscribeVD request to HMI
-- 3) HMI sends OnVD notification with subscribed VD
-- SDL does:
--  a) resend OnVD notification to both mobile apps.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local appId1 = 1
local appId2 = 2
local isExpectedSubscribeVDonHMI = true
local notExpectedSubscribeVDonHMI = false
local rpcNameSubscribeVD = "SubscribeVehicleData"
local isExpected = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App1", common.registerAppWOPTU, { appId1 })
common.Step("Register App2", common.registerAppWOPTU, { appId2 })
common.Step("Activate App1", common.activateApp, { appId1 })
common.Step("Activate App2", common.activateApp, { appId2 })
common.Step("App1 subscribes to windowStatus data", common.subUnScribeVD,
  { rpcNameSubscribeVD, isExpectedSubscribeVDonHMI, appId1 })
common.Step("App2 subscribes to windowStatus data", common.subUnScribeVD,
  { rpcNameSubscribeVD, notExpectedSubscribeVDonHMI, appId2 })
common.Step("Ignition Off", common.ignitionOff)
common.Step("Ignition On", common.start)

common.Title("Test")
common.Step("Re-register App1 resumption data", common.registerAppWithResumption,
  { appId1, isExpectedSubscribeVDonHMI })
common.Step("Re-register App2 resumption data", common.registerAppWithResumption,
  { appId2, notExpectedSubscribeVDonHMI })
common.Step("Activate App1", common.activateApp)
common.Step("OnVehicleData with windowStatus data for both apps", common.onVehicleDataTwoApps, { isExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
