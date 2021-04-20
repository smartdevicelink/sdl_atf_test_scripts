--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--
--  Description:
--  Check that it is able to register 5 sessions within 1 phisycal connection.
--  Sessions have to be added one by one.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--  Mobile device is connected to system.
--  1 session is added, 1 app is registered.
--
--  2. Performed steps
--  Add 2 session
--  appID_2->RegisterAppInterface(params)
--  Add 3 session
--  appID_3->RegisterAppInterface(params)
--  Add 4 session
--  appID_4->RegisterAppInterface(params)
--  Add 5 session
--  appID_5->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL successfully registers all four applications and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--  2. SDL assignes HMILevel after application registering:
--     SDL->appID: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
---------------------------------------------------------------------------------------------------

-- [[ Required Shared Libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)

runner.Title("Test")
for i = 1, 5 do
  runner.Step("Register App " .. i, common.registerApp, { i })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)


