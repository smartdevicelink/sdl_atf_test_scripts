---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- 1) HMI sends OnRemoteControlSettings notification with no parameters
-- SDL must:
-- 1) Do not take into account this request
-- 2) Leave previously defined access mode
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

local function setRAMode(self)
  local rpc = "OnRemoteControlSettings"
  local params = { } -- no parameters
  self.hmiConnection:SendNotification(commonRC.getHMIEventName(rpc), params)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App1", commonRC.activate_app)
runner.Step("RAI2", commonRC.rai_n, { 2 })

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })

  runner.Title("RA mode Default AUTO_ALLOW")
  runner.Step("Activate App2", commonRC.activate_app, { 2 })
  runner.Step("Send OnRemoteControlSettings with invalid data", setRAMode)
  runner.Step("App2 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })

  runner.Title("RA mode AUTO_DENY")
  runner.Step("Set RA mode", commonRC.defineRAMode, { true, "AUTO_DENY" })
  runner.Step("Activate App1", commonRC.activate_app, { 1 })
  runner.Step("Send OnRemoteControlSettings with invalid data", setRAMode)
  runner.Step("App2 SetInteriorVehicleData", commonRC.rpcDenied, { mod, 1, "SetInteriorVehicleData", "IN_USE" })

  runner.Title("RA mode ASK_DRIVER")
  runner.Step("Set RA mode", commonRC.defineRAMode, { true, "ASK_DRIVER" })
  runner.Step("Send OnRemoteControlSettings with invalid data", setRAMode)
  runner.Step("App2 ButtonPress 1st SUCCESS", commonRC.rpcAllowedWithConsent, { mod, 1, "SetInteriorVehicleData" })
  runner.Step("App2 ButtonPress 2nd SUCCESS", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })

  runner.Title("RA mode AUTO_ALLOW")
  runner.Step("Set RA mode", commonRC.defineRAMode, { true, "AUTO_ALLOW" })
  runner.Step("Activate App2", commonRC.activate_app, { 2 })
  runner.Step("Send OnRemoteControlSettings with invalid data", setRAMode)
  runner.Step("App2 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
  runner.Step("Activate App1", commonRC.activate_app, { 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
