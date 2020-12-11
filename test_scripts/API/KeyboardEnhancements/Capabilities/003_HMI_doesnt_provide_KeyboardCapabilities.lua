----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is still able to receive 'WindowCapabilities' from HMI without 'KeyboardCapabilities'
-- and transfer them to App
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'WindowCapabilities' without 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App requests 'DISPLAYS' system capabilities through 'GetSystemCapability'
-- SDL does:
--  - Provide 'WindowCapabilities' without 'KeyboardCapabilities' to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local dispCaps = common.getDispCaps()
dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = nil

--[[ Local Functions ]]
local function check(_, data)
  if data.payload.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities ~= nil then
    return false, "Unexpected 'keyboardCapabilities' parameter received"
  end
  return true
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSCU", common.sendOnSCU, { dispCaps, common.expected.yes, check })
common.Step("App sends GetSC", common.sendGetSC, { dispCaps, common.result.success, check })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
