---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
--
-- Description:
-- In case:
-- 1) By policy OnDriverDistractions allowed for (FULL, LIMITED, BACKGROUND, NONE) HMILevel
-- 2) HMI sends invalid "OnDriverDistractions" notification to SDL:
--  a) invalid data type
--  b) empty value
-- SDL does:
-- 1) Send OnDriverDistraction notification to mobile with "lockScreenDismissalEnabled" parameter and all mandatories
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SDL_Passenger_Mode/commonPassengerMode')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local invalidValue = {
	"Invalid data type",  -- invalid data type
  ""                    -- empty value
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation HMI level FULL", common.activateApp)

runner.Title("Test")
for _, v in ipairs(common.OnDDValue) do
  for _, k in ipairs(invalidValue) do
    runner.Step("OnDriverDistraction with state " .. v .. " and invalid value lockScreenDismissalEnabled",
    common.onDriverDistractionUnsuccess, { v, k })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
