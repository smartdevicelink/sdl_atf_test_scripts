---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Successful processing of SubscribeVehicleData with `windowStatus` parameter.
--
-- In case:
-- 1) App sends SubscribeVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI responds with `SUCCESS` result to SubscribeVehicleData request and with not success result to `windowStatus` vehicle data
-- SDL does:
--  a) respond `SUCCESS`, success:true and with `windowStatus` data to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("Absence OnVehicleData before subscription", common.sendOnVehicleData,
  { common.getWindowStatusParams(), notExpected })

common.Title("Test")
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { rpc })
common.Step("OnVehicleData after subscription", common.sendOnVehicleData, { common.getWindowStatusParams() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
