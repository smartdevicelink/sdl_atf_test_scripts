---------------------------------------------------------------------------------------------------
--  Issue: https://github.com/smartdevicelink/sdl_core/issues/3783
--
--  Steps:
--  1) Register and activate 5 apps
--  2) Change VR Language
--
--  Expected:
--  1) Core does not crash
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local functions ]]
function changeLanguage(pLanguage)
  common.getHMIConnection():SendNotification("VR.OnLanguageChange", { language = pLanguage })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
for i = 1, 5 do
  runner.Step("RAI App", common.registerAppWOPTU, { i })
end

for j = 1, 5 do
  runner.Step("Activate App", common.activateApp, { j })
end

runner.Title("Test")
runner.Step("Change VR Language", changeLanguage, { "FR-CA" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
