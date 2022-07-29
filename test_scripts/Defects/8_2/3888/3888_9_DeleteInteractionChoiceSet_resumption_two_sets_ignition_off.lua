---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3888
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL requests VR.DeleteCommand only for choice set with VR command during erroneous resumption
--  after unexpected disconnect
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
--
-- Test:
-- 1. Mobile app adds CreateInteractionChoiceSet with and without VR command
-- 2. AddSubMenu is added
-- 3. Ignition OFF and ON are performed
-- 4. Mobile app requests RAI with actual hashId
-- SDL does:
--  - restore UI part of CreateInteractionChoiceSet internally and
--    request VR.AddCommand("type":"Choice") only in case CreateInteractionChoiceSet was added with VR command
-- 5. HMI responds with "SUCCESS" to VR.AddCommands and with erroneous result code to AddSubMenu
-- SDL does:
--  - remove UI part of CreateInteractionChoiceSet internally and request VR.DeleteCommand only for choice set that
--     was added with VR command
--  - send RAI response with "RESUME_FAILED" result code after resumption data is removed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_2/3888/common")

--[[ Test Configuration ]]
local result = "INVALID_ID"
common.testCases.with_vr_command.performInteractionVR.result = result
common.testCases.without_vr_command.performInteractionMANUAL.result = result

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("CreateInteractionChoiceSet with vr command", common.createInteractionChoiceSet,
  { common.testCases.with_vr_command })
common.Step("CreateInteractionChoiceSet without vr command", common.createInteractionChoiceSet,
  { common.testCases.without_vr_command })
common.Step("AddSubMenu", common.addSubMenu)
common.Step("Ignition OFF", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI with resumption", common.raiWithResumption,
  { common.testCases.with_vr_command, common.addSubMenuResumptionFail, common.resumeFailedResult })
common.Step("PerformInteraction VR", common.performInteractionVR,
  { common.testCases.with_vr_command.performInteractionVR })
common.Step("PerformInteraction MANUAL", common.performInteractionMANUAL,
  { common.testCases.without_vr_command.performInteractionMANUAL })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)