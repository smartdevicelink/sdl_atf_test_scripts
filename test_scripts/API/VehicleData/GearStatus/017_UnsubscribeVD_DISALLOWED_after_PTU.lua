---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL rejects the request with `DISALLOWED` resultCode if app tries to unsubscribe from 'gearStatus'
-- vehicle data and parameter 'gearStatus' is not present in app assigned policies after PTU.
--
-- Preconditions:
-- 1) All vehicle data RPCs with the `gearStatus` parameter exist in app assigned policies.
-- 2) SubscribeVehcileData and UnsubscribeVehicleData RPCs are successfully processed.
-- In case:
-- 1) Policy Table Update is performed and "gearStatus" parameter is unassigned for the app.
-- 2) App sends UnsubscribeVehicleData request with gearStatus=true to the SDL.
-- SDL does:
--  a) not transfer this request to HMI.
--  b) send response UnsubscribeVehicleData(success:false, "DISALLOWED") to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local result = "DISALLOWED"

--[[ Local Function ]]
local function pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gearStatus" }
      },
      UnsubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "LIMITED", "FULL" },
        parameters = { "gps" }
      }
    }
  }
  tbl.policy_table.functional_groupings.NewVehicleDataGroup = VDgroup
  tbl.policy_table.app_policies[common.getAppParams().fullAppID].groups = { "Base-4", "NewVehicleDataGroup" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc_sub })
common.Step("App unsubscribes from gearStatus data", common.processSubscriptionRPC, { rpc_unsub })

common.Title("Test")
common.Step("PTU is performed, gearStatus is unassigned for the app", common.policyTableUpdate, { pTUpdateFunc })
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc_sub })
common.Step("App unsubscribes from gearStatus data DISALLOWED", common.processRPCFailure, { rpc_unsub, result })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
