---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
--
-- Description:
-- In case:
-- 1) By policy OnDriverDistraction allowed for (FULL, LIMITED, BACKGROUND) HMILevel
-- 2) App registered (HMI level NONE)
-- 3) HMI sends "lockScreenDismissalEnabled"=true (and all mandatory fields) as a parameter
--    of OnDriverDistraction notification
-- 4) App activated (HMI level FULL)
-- 5) HMI sends valid OnDriverDistraction notification with "lockScreenDismissalEnabled"=false param
-- SDL does:
-- 1) Not send  OnDriverDistraction notification to mobile when (HMI level NONE)
-- 2) Send OnDriverDistraction notification to mobile with "lockScreenDismissalEnabled"=true once app is activated
-- 3) Send OnDriverDistraction notification to mobile with "lockScreenDismissalEnabled"=false once HMI sends it
--    to SDL when app is in FULL
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
runner.Step("App registration HMI level NONE", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.ptuFunc })

runner.Title("Test")
runner.Step("OnDriverDistraction with state DD_ON with lockScreenDismissalEnabled true",
  common.onDriverDistractionUnsuccess, { "DD_ON", true })

runner.Step("App activation HMI level FULL", common.activateApp)

for _, v in pairs(common.OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled true",
  common.onDriverDistraction, { v, true })
end

for _, v in pairs(common.OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled false",
  common.onDriverDistraction, { v, false })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
