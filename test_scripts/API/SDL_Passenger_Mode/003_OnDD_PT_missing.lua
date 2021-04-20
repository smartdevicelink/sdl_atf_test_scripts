---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
-- Description:
-- In case:
-- 1) OnDriverDistraction notification is  allowed by Policy for (FULL, LIMITED, BACKGROUND, NONE) HMILevel
-- 2) In Policy "lock_screen_dismissal_enabled" parameter is missing
-- 3) App registered (HMI level NONE)
-- 4) HMI sends OnDriverDistraction notifications with state=DD_OFF and then with state=DD_ON one by one
-- SDL does:
--  - Send OnDriverDistraction(DD_OFF) notification to mobile without both "lockScreenDismissalEnabled"
--    and "lockScreenDismissalWarning" parameters and all mandatory fields
--  - Send OnDriverDistraction(DD_ON) notification to mobile without both "lockScreenDismissalEnabled"
--    and "lockScreenDismissalWarning" parameters and all mandatory fields
-- Note: Cover all HMI levels
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SDL_Passenger_Mode/commonPassengerMode')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local lockScreenDismissalEnabled = nil

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set LockScreenDismissalEnabled", common.updatePreloadedPT, { lockScreenDismissalEnabled })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWithOnDD)

runner.Title("Test")

for _, level in common.pairs(common.hmiLevel) do
  runner.Step("Switch app's HMI level to " .. level.name, level.func)
  runner.Step("OnDriverDistraction OFF missing", common.onDriverDistraction, { "DD_OFF", lockScreenDismissalEnabled })
  runner.Step("OnDriverDistraction ON missing", common.onDriverDistraction, { "DD_ON", lockScreenDismissalEnabled })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
