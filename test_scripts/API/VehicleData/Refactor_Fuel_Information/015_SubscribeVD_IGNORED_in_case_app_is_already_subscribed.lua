---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: SDL sends response with resultCode IGNORED to SubscribeVehicleData in case app is already subscribed
--  to `FuelRange` data
-- In case:
-- 1) App is subscribed to `FuelRange` data
-- 2) App sends SubscribeVehicleData(FuelRange=true) data to SDL
-- SDL does:
-- 1) respond with resultCode IGNORED to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

--[[ Local Functions ]]
local function subscribeVDignored()
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", { fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData") :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "IGNORED" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to fuelRange data", common.subUnScribeVD, { "SubscribeVehicleData", common.subUnsubParams })

common.Title("Test")
  common.Step("SubscribeVehicleData IGNORED", subscribeVDignored)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
