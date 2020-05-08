---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- HMI didn't send OnRemoteControlSettings notifications on systems start
--
-- SDL must:
-- use default value allowed:true and accessMode = "AUTO_ALLOW" for all registered REMOTE_CONTROL applications
-- until OnRemoteControlSettings notification with other settings is received
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
--modules array does not contain "RADIO" because "RADIO" module has read only parameters
local modules = { "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI1", common.registerAppWOPTU)
runner.Step("RAI2", common.registerAppWOPTU, { 2 })

runner.Title("Test")
for _, mod in pairs(modules) do
  runner.Step("Activate App2", common.activateApp, { 2 })
  runner.Step("Check module " .. mod .." App2 SetInteriorVehicleData allowed",
    common.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
  runner.Step("Activate App1", common.activateApp)
  runner.Step("Check module " .. mod .." App1 SetInteriorVehicleData allowed",
    common.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
