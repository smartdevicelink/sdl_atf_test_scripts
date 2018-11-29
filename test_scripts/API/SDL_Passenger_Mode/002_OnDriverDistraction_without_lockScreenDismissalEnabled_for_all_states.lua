-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
--
-- Description:
-- In case:
-- 1) By policy OnDriverDistractions allowed for (FULL, LIMITED, BACKGROUND, NONE) HMILevel
-- 2) App registered (HMI level NONE)
-- 3) HMI not sends "lockScreenDismissalEnabled" item (boolean) (with all mandatories) as a parameter of OnDriverDistraction notification
-- 4) App activated (HMI level FULL)
-- 5) HMI not sends "lockScreenDismissalEnabled" item (boolean) (with all mandatories) as a parameter of OnDriverDistraction notification
-- 6) Mobile app received OnHMIStatus (hmiLevel = "LIMITED")
-- 7) HMI not sends "lockScreenDismissalEnabled" item (boolean) (with all mandatories) as a parameter of OnDriverDistraction notification
-- 8) Mobile app received OnHMIStatus (hmiLevel = "BACKGROUND")
-- 9) HMI not sends "lockScreenDismissalEnabled" item (boolean) (with all mandatories) as a parameter of OnDriverDistraction notification
-- SDL does:
-- 1) Send OnDriverDistraction notification to mobile with "lockScreenDismissalEnabled" parameter and all mandatories
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SDL_Passenger_Mode/commonPassengerMode')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration HMI level NONE", common.registerAppWOPTU)
for _, v in ipairs(common.OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " without lockScreenDismissalEnabled", common.onDriverDistraction, { v, nil })
end

runner.Step("App activation HMI level FULL", common.activateApp)
for _, v in ipairs(common.OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " without lockScreenDismissalEnabled", common.onDriverDistraction, { v, nil })
end

runner.Step("Deactivate app HMI level LIMITED", common.deactivateAppToLimited)
for _, v in ipairs(common.OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " without lockScreenDismissalEnabled", common.onDriverDistraction, { v, nil })
end

runner.Step("Deactivate app HMI level BACKGROUND", common.deactivateAppToBackground)
for _, v in ipairs(common.OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled",common.onDriverDistraction, { v, nil })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
