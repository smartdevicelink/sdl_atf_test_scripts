---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3858
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL transfers success result code in result structure from HMI to the mobile app
-- during processing of CreateInteractionChoiceSet

-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
--
-- Steps:
-- 1. Mobile app requests CreateInteractionChoiceSet RPC with vrCommands
-- 2. SDL sends VR.AddCommand(type="Choice") request to the HMI
-- 3. HMI responds with success result code in result structure to VR.AddCommand
--
-- SDL does:
-- 1. send CreateInteractionChoiceSet(success = true, resultCode = <code received from HMI>) response to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_1/3858/common_3858')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for choiceId, resultCode in ipairs(common.tcs) do
  local response = { code = resultCode, structure = common.responsesStructures.result }
  runner.Title("Test case: '" .. tostring(resultCode) .. "'" )
  runner.Step("CreateInteractionChoiceSet response with success = true", common.createInteractionChoiceSet,
    { choiceId, response })
  runner.Step("PerformInteraction with added choice set", common.performInteraction,{ choiceId })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

