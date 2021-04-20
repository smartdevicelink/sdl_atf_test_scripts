----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to receive 'KeyboardCapabilities' from HMI and transfer them to App
-- in case one parameter is defined with valid values (edge scenarios)
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App requests 'DISPLAYS' system capabilities through 'GetSystemCapability'
-- SDL does:
--  - Provide 'KeyboardCapabilities' to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local tcs = {
  [01] = { maskInputCharactersSupported = false },
  [02] = { maskInputCharactersSupported = true },
  [03] = { supportedKeyboards = common.getArrayValue({ { keyboardLayout = "QWERTY", numConfigurableKeys = 1 }}, 1) },
  [04] = { supportedKeyboards = common.getArrayValue({ { keyboardLayout = "QWERTY", numConfigurableKeys = 0 }}, 5) },
  [05] = { supportedKeyboards = common.getArrayValue({ { keyboardLayout = "QWERTY", numConfigurableKeys = 5 }}, 1000) },
  [06] = { supportedKeyboards = common.getArrayValue({ { keyboardLayout = "QWERTY", numConfigurableKeys = 10 }}, 5) }
}

--[[ Local Functions ]]
local function getDispCaps(pTC)
  local dispCaps = common.getDispCaps()
  dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = pTC
  return dispCaps
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for tc, data in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  local dispCaps = getDispCaps(data)
  common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { dispCaps })
  common.Step("App sends GetSystemCapability", common.sendGetSystemCapability, { dispCaps })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
