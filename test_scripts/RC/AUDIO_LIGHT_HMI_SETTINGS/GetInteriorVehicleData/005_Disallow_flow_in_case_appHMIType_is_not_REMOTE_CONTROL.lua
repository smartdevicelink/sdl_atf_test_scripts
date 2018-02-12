---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/7
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/Policy_Support_of_basic_RC_functionality.md
-- Item: Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) Non remote-control application is registered on SDL
-- 2) and SDL received GetInteriorVehicleData request from this App
-- SDL must:
-- 1) Disallow remote-control RPCs for this app (success:false, "DISALLOWED")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function getDataForModule(pModuleType)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType
    })
  EXPECT_HMICALL("RC.GetInteriorVehicleData")
  :Times(0)
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

local function ptu_update_func(tbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId].AppHMIType = { "DEFAULT" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n, { ptu_update_func })
runner.Step("Activate App", common.activate_app)

runner.Title("Test")

for _, mod in pairs(common.modules) do
  runner.Step("GetInteriorVehicleData " .. mod, getDataForModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
