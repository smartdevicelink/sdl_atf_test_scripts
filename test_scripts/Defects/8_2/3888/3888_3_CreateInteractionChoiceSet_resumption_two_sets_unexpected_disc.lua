---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3888
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL resumes both CreatedInteractionChoiceSets (one with and one without VR commands)
--  after unexpected disconnects
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
--
-- Test:
-- 1. Mobile app adds CreateInteractionChoiceSet with and without VR command
-- 2. Unexpected disconnect is performed
-- 3. Mobile app requests RAI with actual hashId
-- SDL does:
--  - restore UI part of CreateInteractionChoiceSet internally for both sets and
--     request VR.AddCommand("type":"Choice") for set that was added with VR command
--  - send RAI response with "SUCCESS" result code after resumption data is succeeded
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Defects/8_2/3888/common")

--[[ Test ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Step("CreateInteractionChoiceSet with vr command", common.createInteractionChoiceSet,
  { common.testCases.with_vr_command })
common.Step("CreateInteractionChoiceSet without vr command", common.createInteractionChoiceSet,
  { common.testCases.without_vr_command })
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("RAI with resumption", common.raiWithResumption, { common.testCases.with_vr_command })
common.Step("PerformInteraction VR", common.performInteractionVR,
  { common.testCases.with_vr_command.performInteractionVR })
common.Step("PerformInteraction MANUAL", common.performInteractionMANUAL,
  { common.testCases.without_vr_command.performInteractionMANUAL })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)