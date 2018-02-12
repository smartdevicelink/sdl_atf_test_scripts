---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
-- [SDL_RC] Policy support of basic RC functionality
--
-- Description:
-- In case:
-- 1) "moduleType" in app's assigned policies has an empty array
-- 2) and RC app sends GetInteriorVehicleData request with valid parameters
-- SDL must:
-- 1) Allow this RPC to be processed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local json = require('modules/json')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local function ptu_update_func(tbl)
  common.AddOnRCStatusToPT(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId] = common.getRCAppConfig()
  tbl.policy_table.app_policies[appId].moduleType = json.EMPTY_ARRAY
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n, { ptu_update_func })
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
for _, mod in pairs(common.modules) do
  runner.Step("GetInteriorVehicleData " .. mod, common.rpcAllowed, { mod, 1, "GetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
