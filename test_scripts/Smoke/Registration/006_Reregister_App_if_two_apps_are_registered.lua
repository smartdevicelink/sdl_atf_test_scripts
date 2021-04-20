--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--  [UnregisterAppInterface] Unregistering an application
--
--  Description:
--  Check that it is able to reregister App if several Apps are registered.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--  Mobile device is connected to system.
--  2 Apps are registered.
--
--  2. Performed steps
--  app_1->SDL: UnregisterAppInterface(params)
--  appID_1->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL->appID_1: (SUCCESS, success:true):UnregisterAppInterface()
--     SDL->HMI: OnAppUnregistered(hmi_appID_1, unexpectedDisсonnect:false)
--     app_2 still registered.
--  2. SDL successfully registers app_1 and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID_1: SUCCESS, success:"true":RegisterAppInterface()
--  3. SDL assignes HMILevel after application registering:
--     SDL->appID_1: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
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
runner.Step("Register App 1", common.registerApp, { 1 })
runner.Step("Register App 2", common.registerApp, { 2 })
runner.Step("UnRegister App 1", common.unregisterApp, { 1 })
runner.Step("ReRegister App 1", common.registerApp, { 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
