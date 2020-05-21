---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL doesn't transfer OnVehicleData notification to App if 'handsOffSteering' parameter is not
-- allowed by policy after PTU
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs SubscribeVehicleData, OnVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered and subscribed to handsOffSteering data
--
-- In case:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) transfer this notification to App
-- 3) PTU is performed with disabling permissions for handsOffSteering parameter
-- 1) HMI sends VehicleInfo.OnVehicleData notification with handsOffSteering data to SDL
-- SDL does:
-- - a) ignored this notification and not transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local notExpected = 0
local expected = 1

--[[ Local Function ]]
local function ptUpdate(pt)
  local pGroups = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = { "gps" }
      },
      OnVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = { "handsOffSteering" }
      }
    }
  }
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.app_policies[common.getAppParams().fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering data",
  common.processSubscriptionRPC, { rpc })
common.Step("OnVehicleData notification with handsOffSteering data", common.sendOnVehicleData, { expected })

common.Title("Test")
common.Step("Policy Table Update with disabling permissions for handsOffSteering",
  common.policyTableUpdate, { ptUpdate })
common.Step("Absence OnVehicleData notification with handsOffSteering data", common.sendOnVehicleData, { notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
