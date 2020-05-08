---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2405
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/5_0/2405/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local grp = {
  [1] = { name = "Dummy-1", prompt = "Dummy_1", params = common.EMPTY_ARRAY },
  [2] = { name = "Dummy-2", prompt = "Dummy_2", params = { "speed" } }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate, { grp })

runner.Title("Test")
runner.Step("Send GetListOfPermissions", common.getListOfPermissions, { grp })
runner.Step("Consent Groups", common.consentGroups, { grp })
runner.Step("Send GetVehicleData speed", common.getVD, { "speed", "SUCCESS", true })
runner.Step("Send GetVehicleData rpm", common.getVD, { "rpm", "DISALLOWED", false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
