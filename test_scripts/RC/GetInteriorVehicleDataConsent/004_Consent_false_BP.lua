---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #5; TRS: GetInteriorVehicleDataConsent, #4
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with "ASK_DRIVER" access mode
-- 2) and RC application (in HMILevel FULL) requested access to remote control module
-- that is already allocated to another RC application
-- 3) and SDL requested user consent from HMI via GetInteriorVehicleDataConsent
-- 4) and user disallowed access to RC module for the requested application
-- SDL must:
-- 1) respond on control request to RC application with result code REJECTED, success:false,
-- info: "The resource is in use and the driver disallows this remote control RPC"
-- 2) not allocate access for remote control module to the requested application
-- (meaning SDL must leave control of remote control module without changes)
-- Note: All further requests from this application to the same module in case
-- if it is still under control of another application must be rejected by SDL without initiating consent prompts
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App1", commonRC.activate_app)
runner.Step("RAI2", commonRC.rai_n, { 2 })
runner.Step("Activate App2", commonRC.activate_app, { 2 })

runner.Title("Test")
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  -- set control for App1
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  -- set control for App2 --> Ask driver --> HMI: allowed:false
  runner.Step("App2 ButtonPress 1st REJECTED", commonRC.rpcRejectWithConsent, { mod, 2, "ButtonPress" })
  runner.Step("App2 ButtonPress 2nd REJECTED", commonRC.rpcRejectWithoutConsent, { mod, 2, "ButtonPress" })
  runner.Step("App2 SetInteriorVehicleData 2nd REJECTED", commonRC.rpcRejectWithoutConsent, { mod, 2, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
