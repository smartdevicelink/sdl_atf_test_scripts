---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: SDL sends response with resultCode IGNORED to UnsubscribeVehicleData in case app is already unsubscribed
--  from `FuelRange` data
-- In case:
-- 1) App is subscribed to `FuelRange` data
-- 2) App is unsubscribed from `FuelRange` data
-- 3) App sends UnsubscribeVehicleData(FuelRange=true) data to SDL
-- SDL does:
-- 1) respond with resultCode IGNORED to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

--[[ Local Functions ]]
local function unsubscribeVDignored()
  local cid = common.getMobileSession():SendRPC("UnsubscribeVehicleData", { fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData") :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "IGNORED" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to fuelRange data", common.subUnScribeVD,
  { "SubscribeVehicleData", common.subUnsubParams })
common.Step("App unsubscribes from fuelRange data", common.subUnScribeVD,
  { "UnsubscribeVehicleData", common.subUnsubParams })

common.Title("Test")
  common.Step("UnsubscribeVehicleData IGNORED", unsubscribeVDignored)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
