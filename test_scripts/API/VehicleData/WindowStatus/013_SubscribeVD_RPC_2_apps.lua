---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL processes SubscribeVehicleData RPC for two Apps with `windowStatus` parameter
--
-- Preconditions:
-- 1) RPC SubscribeVehicleData and `windowStatus` parameter are allowed by policies
-- 2) App_1 and App_2 are registered
--
-- In case:
-- 1) App_1 requests SubscribeVehicleData(windowStatus=true)
-- SDL does:
--  a) transfer this request to HMI
-- 2) HMI sends successful VehicleInfo.SubscribeVehicleData response with windowStatus data to SDL
-- SDL does:
--  a) send SubscribeVehicleData(success = true, resultCode = SUCCESS", windowStatus = <data received from HMI>)
--  response to App_1
-- 3) App_2 requests SubscribeVehicleData(windowStatus=true)
-- SDL does:
--  a) not transfer this request to HMI
--  b) send SubscribeVehicleData(success = true, resultCode = SUCCESS", windowStatus = <data received from HMI>)
--  response to App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variable ]]
local rpc = "SubscribeVehicleData"
local firstAppId = 1
local secondAppId = 2
local isExpectedSubscribeVDonHMI = true
local notExpectedSubscribeVDonHMI = false
local isExpected = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerApp, { firstAppId })
common.Step("Register App_2", common.registerAppWOPTU, { secondAppId })

common.Title("Test")
common.Step("App_1 subscribes to windowStatus data",
  common.subUnScribeVD, { rpc, isExpectedSubscribeVDonHMI, firstAppId })
common.Step("App_2 subscribes to windowStatus data",
  common.subUnScribeVD, { rpc, notExpectedSubscribeVDonHMI, secondAppId })
common.Step("OnVehicleData to App_1 and App_2", common.onVehicleDataTwoApps, { isExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
