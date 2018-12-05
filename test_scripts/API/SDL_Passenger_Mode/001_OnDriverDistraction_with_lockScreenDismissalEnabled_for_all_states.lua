---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
--
-- Description:
-- In case:
-- 1) By policy OnDriverDistraction allowed for (FULL, LIMITED, BACKGROUND, NONE) HMILevel
-- 2) App registered and activated (HMI level FULL)
-- 3)  HMI sends "lockScreenDismissalEnabled" item (boolean) (with all mandatory fields) as a parameter
--     of OnDriverDistraction notification
-- Note: Covers all hmi levels
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
runner.Step("App registration HMI level NONE", common.registerApp)
for _, k in ipairs(common.value) do
  for _, v in ipairs(common.OnDDValue) do
    runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled " .. tostring(k),
		common.onDriverDistraction, { v, k })
  end
end

runner.Step("App activation HMI level FULL", common.activateApp)
for _, k in ipairs(common.value) do
  for _, v in ipairs(common.OnDDValue) do
    runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled " .. tostring(k),
    common.onDriverDistraction, { v, k })
  end
end

runner.Step("Deactivate app HMI level LIMITED", common.deactivateAppToLimited)
for _, k in ipairs(common.value) do
  for _, v in ipairs(common.OnDDValue) do
    runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled " .. tostring(k),
    common.onDriverDistraction, { v, k })
  end
end

runner.Step("Deactivate app HMI level BACKGROUND", common.deactivateAppToBackground)
for _, k in ipairs(common.value) do
  for _, v in ipairs(common.OnDDValue) do
    runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled " .. tostring(k),
    common.onDriverDistraction, { v, k })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
