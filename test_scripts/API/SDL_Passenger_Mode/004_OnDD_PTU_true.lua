---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
-- Description:
-- In case:
-- 1) OnDriverDistraction notification is  allowed by Policy for (FULL, LIMITED, BACKGROUND, NONE) HMILevel
-- 2) In Policy "lock_screen_dismissal_enabled" parameter is missing
-- 3) App registered (HMI level NONE)
-- 4) HMI sends OnDriverDistraction notifications with state=DD_OFF and then with state=DD_ON one by one
-- SDL does:
--  - Resend OnDriverDistraction notification to mobile without both "lockScreenDismissalEnabled"
--    and "lockScreenDismissalWarning" parameters
-- 5) Policy Table update ("lock_screen_dismissal_enabled" = true)
-- SDL does:
--  - Send OnDriverDistraction(DD_ON) notification to mobile with both "lockScreenDismissalEnabled"=true
--    and "lockScreenDismissalWarning" parameters
-- 6) HMI sends OnDriverDistraction notifications with state=DD_OFF and then with state=DD_ON one by one
-- SDL does:
--  - Resend OnDriverDistraction(DD_OFF) notification to mobile without both "lockScreenDismissalEnabled"
--    and "lockScreenDismissalWarning" parameters
--  - Resend OnDriverDistraction(DD_ON) notification to mobile with both "lockScreenDismissalEnabled"=true
--    and "lockScreenDismissalWarning" parameters
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SDL_Passenger_Mode/commonPassengerMode')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local lockScreenDismissalEnabled = true

--[[ Local Functions ]]
local function ptUpdate(pPT)
  pPT.policy_table.module_config.lock_screen_dismissal_enabled = lockScreenDismissalEnabled
end

local function ptuWithOnDD()
  common.expOnDriverDistraction("DD_ON", lockScreenDismissalEnabled)
  common.policyTableUpdate(ptUpdate)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set LockScreenDismissalEnabled", common.updatePreloadedPT, { nil })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWithOnDD)

runner.Title("Test")
runner.Step("OnDriverDistraction OFF missing", common.onDriverDistraction, { "DD_OFF", nil })
runner.Step("OnDriverDistraction ON missing", common.onDriverDistraction, { "DD_ON", nil })
runner.Step("Policy Table Update", ptuWithOnDD)
runner.Step("OnDriverDistraction OFF true", common.onDriverDistraction, { "DD_OFF", lockScreenDismissalEnabled })
runner.Step("OnDriverDistraction ON true", common.onDriverDistraction, { "DD_ON", lockScreenDismissalEnabled })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
