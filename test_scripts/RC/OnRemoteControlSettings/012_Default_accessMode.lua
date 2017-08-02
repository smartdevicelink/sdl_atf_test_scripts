---------------------------------------------------------------------------------------------------
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

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

local rcRpcs = { "SetInteriorVehicleData", "ButtonPress" }

--[[ Local Functions ]]

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("RAI2", commonRC.rai_n, { 2 })

runner.Title("Test")
for _, mod in pairs(modules) do
  for _, rpc in pairs(rcRpcs) do
    runner.Step("Activate App2", commonRC.activate_app, { 2 })
    runner.Step("Check module " .. mod .." App2 " .. rpc .. " allowed", commonRC.rpcAllowed, { mod, 2, rpc })
     runner.Step("Activate App1", commonRC.activate_app)
    runner.Step("Check module " .. mod .." App1 " .. rpc .. " allowed", commonRC.rpcAllowed, { mod, 1, rpc })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
