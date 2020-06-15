---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check that SDL rejects SubscribeVehicleData request with resultCode "IGNORED" in case
--  app is already subscribed to 'stabilityControlsStatus' data
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) App is subscribed to 'stabilityControlsStatus' data
--
-- In case:
-- 1) App sends valid SubscribeVehicleData(stabilityControlsStatus=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = "IGNORED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to stabilityControlsStatus parameter", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "stabilityControlsStatus" }})

common.Title("Test")
common.Step("SubscribeVehicleData with stabilityControlsStatus parameter IGNORED",
  common.processRPCSubscriptionIgnored, { "SubscribeVehicleData", "stabilityControlsStatus" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
