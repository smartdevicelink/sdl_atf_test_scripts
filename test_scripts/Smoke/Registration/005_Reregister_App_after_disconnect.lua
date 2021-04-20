--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--  [Unexpected Disconnect]: 6. "unexpectedDisconnect:true" in case of transport issues
--
--  Description:
--  Check that it is able to reregister App after connection was closed.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--  Mobile device is connected to system.
--  Application with appID is registered on SDL.
--
--  2. Performed steps
--  Turn off transport, turn on transport
--  appID->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL->HMI: OnAppUnregistered (appID, "unexpectedDisconnect: true")
--  2. SDL successfully registers application and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--  3. SDL assignes HMILevel after application registering:
--     SDL->appID: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
---------------------------------------------------------------------------------------------------

--[[ Required Shared Libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("ReRegister App", common.registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
