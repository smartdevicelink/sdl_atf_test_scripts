--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--  [UnregisterAppInterface] Unregistering an application
--
--  Description:
--  Check that it is able to reregister App within current connection.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--  Mobile device is connected to system.
--  Application with appID is registered on SDL.
--
--  2. Performed steps
--  app->SDL: UnregisterAppInterface(params)
--  appID->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL->appID: (SUCCESS, success:true):UnregisterAppInterface()
--     SDL->HMI: OnAppUnregistered(hmi_appID, unexpectedDisсonnect:false)
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
runner.Step("UnRegister App", common.unregisterApp)
runner.Step("ReRegister App", common.registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
