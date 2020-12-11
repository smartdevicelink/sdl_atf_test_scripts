----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to transfer 'OnKeyboardInput' notification from HMI to App
-- with new values for 'event'
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with 'maskInputCharacters=USER_CHOICE_INPUT_KEY_MASK'
-- 4. HMI sends 'OnKeyboardInput' notification with specific values for 'event':
--   - INPUT_KEY_MASK_ENABLED
--   - INPUT_KEY_MASK_DISABLED
-- SDL does:
--  - Transfer 'OnKeyboardInput' notification to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local sgpParams = {
  keyboardProperties = {
    keyboardLayout = "NUMERIC",
    maskInputCharacters = "USER_CHOICE_INPUT_KEY_MASK"
  }
}

--[[ Local Functions ]]
local function ptUpd(pTbl)
  pTbl.policy_table.app_policies[common.getPolicyAppId()].groups = { "Base-4", "OnKeyboardInputOnlyGroup" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { ptUpd })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("HMI sends OnSCU", common.sendOnSCU)
common.Step("App sends SetGP", common.sendSetGP, { sgpParams, common.result.success })
common.Step("HMI sends OnKI", common.sendOnKI, { { event = "INPUT_KEY_MASK_ENABLED" } })
common.Step("HMI sends OnKI", common.sendOnKI, { { event = "INPUT_KEY_MASK_DISABLED" } })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
