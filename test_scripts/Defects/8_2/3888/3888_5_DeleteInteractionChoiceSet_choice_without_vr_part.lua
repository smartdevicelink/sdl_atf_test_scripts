---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3888
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends VR.DeleteCommand during DeleteInteractionChoice processing only
--  in case choice contains VR command
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
--
-- Test:
-- 1. Mobile app adds CreateInteractionChoiceSet with and without VR command
-- 2. Mobile app requests DeleteInteractionchoiceSet for added choices
-- SDL does:
--  - remove UI part of ChoiceSet internally and request VR.DeleteCommand("type":"Choice") only for choice
--    with VR command
--  - send DeleteInteractionchoiceSet response with "SUCCESS" result code
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_2/3888/common")

--[[ Test Configuration ]]
local result = "INVALID_ID"
common.testCases.with_vr_command.performInteractionVR.result = result
common.testCases.with_vr_command.performInteractionMANUAL.result = result
common.testCases.without_vr_command.performInteractionVR.result = result
common.testCases.without_vr_command.performInteractionMANUAL.result = result

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for k, v in common.spairs(common.testCases) do
  common.Step("CreateInteractionChoiceSet " .. k, common.createInteractionChoiceSet, { v })
  common.Step("DeleteInteractionChoiceSet " .. k, common.deleteInteractionChoiceSet,
    { v.parameters.interactionChoiceSetID, v.vrCommandTimes })
  common.Step("PerformInteraction VR", common.performInteractionVR, { v.performInteractionVR })
  common.Step("PerformInteraction MANUAL", common.performInteractionMANUAL, { v.performInteractionMANUAL })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)