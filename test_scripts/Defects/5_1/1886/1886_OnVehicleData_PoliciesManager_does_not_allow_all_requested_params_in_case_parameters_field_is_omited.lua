---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1886
-- Description: PoliciesManager must allow all requested params in case "parameters" field is omitted
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) App is registered and activated.
-- 3) PTU is performed and "parameters" field is omitted at PolicyTable for used request
-- In case:
-- 1) In case SDL receives OnVehicleData notification from HMI
-- and this notification is allowed by Policies for this mobile app
-- Expected result:
-- 1) SDL must transfer received notification with all parameters as is to mobile app
-- respond with <received_resultCode_from_HMI> to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Defects/5_1/1886/common")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.allVehicleData.vin = nil

--[[ Local Functions ]]
local function ptuUpdateFuncDissalowedRPC(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      },
      OnVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      },
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      },
      UnsubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      },
      SendLocation = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"},
        -- parameters omitted
      }
    }
  }
  tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
  if tbl.policy_table.functional_groupings["SendLocation"] then
    tbl.policy_table.functional_groupings["SendLocation"] = nil
  end
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "NewTestCaseGroup"}
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("`100, 1` in GetVehicleDataRequest in ini file", common.setSDLIniParameter,
  { "GetVehicleDataRequest", "100, 1" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU update", common.policyTableUpdate, { ptuUpdateFuncDissalowedRPC })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("GetVehicleData to " .. vehicleDataName .. " if this param is ommited in PT",
    common.processRPCSuccess, { vehicleDataName })
end

for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("SubscribeVD to " .. vehicleDataName .. " if this param is ommited in PT",
    common.subscribeUnsibscribeSuccess, { "SubscribeVehicleData", vehicleDataName })
end

for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("OnVehicleData for the" .. vehicleDataName .. " if this param is ommited in PT",
    common.checkNotificationSuccess, { vehicleDataName })
end

for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("UnSubscribeVD from" .. vehicleDataName .. " if this param is ommited in PT",
    common.subscribeUnsibscribeSuccess, {"UnsubscribeVehicleData", vehicleDataName } )
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
