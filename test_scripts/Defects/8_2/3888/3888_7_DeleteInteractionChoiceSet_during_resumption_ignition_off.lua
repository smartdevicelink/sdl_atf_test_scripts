---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3888
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL requests VR.DeleteCommand only for choice set with VR command during erroneous resumption
--  after ignition off
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
--
-- Test:
-- 1. Mobile app adds CreateInteractionChoiceSet with or without VR command
-- 2. AddSubMenu is added
-- 3. Ignition OFF and ON are performed
-- 4. Mobile app requests RAI with actual hashId
-- SDL does:
--  - restore UI part of CreateInteractionChoiceSet internally and
--    requests VR.AddCommand("type":"Choice") only in case CreateInteractionChoiceSet was added with VR command
-- 5. HMI responds with SUCCESS to VR.AddCommands and with erroneous result code to AddSubMenu
-- SDL does:
--  - remove UI part of CreateInteractionChoiceSet internally and requests VR.DeleteCommand only for choice set that
--     was added with VR command
--  - send RAI response with "RESUME_FAILED" result code
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
for k, v in common.spairs(common.testCases) do
  common.Title("Test case: CreateInteractionChoiceSet " .. k)
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)

  common.Title("Test")
  common.Step("App requests CreateInteractionChoiceSet " .. k, common.createInteractionChoiceSet, { v })
  common.Step("AddSubMenu", common.addSubMenu)
  common.Step("Ignition OFF", common.ignitionOff)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("RAI with resumption", common.raiWithResumption,
    { v, common.addSubMenuResumptionFail, common.resumeFailedResult })
  common.Step("PerformInteraction VR", common.performInteractionVR, { v.performInteractionVR })
  common.Step("PerformInteraction MANUAL", common.performInteractionMANUAL, { v.performInteractionMANUAL })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end