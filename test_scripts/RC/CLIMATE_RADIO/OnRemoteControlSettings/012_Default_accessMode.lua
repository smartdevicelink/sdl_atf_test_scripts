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
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcRpcs = { "SetInteriorVehicleData", "ButtonPress" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerAppWOPTU)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })

runner.Title("Test")
for _, mod in pairs(commonRC.modules)  do
  for _, rpc in pairs(rcRpcs) do
    runner.Step("Activate App2", commonRC.activateApp, { 2 })
    runner.Step("Check module " .. mod .." App2 " .. rpc .. " allowed", commonRC.rpcAllowed, { mod, 2, rpc })
     runner.Step("Activate App1", commonRC.activateApp)
    runner.Step("Check module " .. mod .." App1 " .. rpc .. " allowed", commonRC.rpcAllowed, { mod, 1, rpc })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
