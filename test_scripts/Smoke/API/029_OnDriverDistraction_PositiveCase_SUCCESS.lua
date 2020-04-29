---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: OnDriverDistraction
-- Item: Happy path
--
-- Requirement summary:
-- [OnDriverDistraction] SUCCESS: getting SUCCESS:UI.OnDriverDistraction()
--
-- Description:
-- HMI sends OnDriverDistraction notification with valid parameters to SDL,
-- SDL resends notification to mobile application successful

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- HMI sends OnDriverDistraction with valid parameters

-- Expected:
-- SDL  receives notification and validates parameters
-- SDL checks if OnDriverDistraction is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers notification with allowed parameters to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local OnDDValue = { "DD_ON", "DD_OFF" }

--[[ Local Functions ]]
local function onDriverDistraction(pOnDDValue)
  local request = { state = pOnDDValue }
  common.getHMIConnection():SendNotification("UI.OnDriverDistraction", request)
  common.getMobileSession():ExpectNotification("OnDriverDistraction", request)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, v in pairs(OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " Positive Case", onDriverDistraction, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
