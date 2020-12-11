----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is unable to provide 'WindowCapabilities' to App
-- in case if HMI has sent 'OnSystemCapabilityUpdated' notification with invalid data
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' with invalid data within 'OnSystemCapabilityUpdated' notification
-- 3. App requests 'DISPLAYS' system capabilities through 'GetSystemCapability'
-- SDL does:
--  - Respond with DATA_NOT_AVAILABLE, success:false to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local keyboardLayouts = { "QWERTY", "QWERTZ", "AZERTY", "NUMERIC" }

local tcs = {
  [01] = { maskInputCharactersSupported = "false" }, --invalid type
  [02] = { supportedKeyboardLayouts = { } },
  [03] = { supportedKeyboardLayouts = common.getArrayValue(keyboardLayouts, 1001) },
  [04] = { configurableKeys = { { keyboardLayout = "QWERTY", numConfigurableKeys = "0" }} },
  [05] = { configurableKeys = { { keyboardLayout = true, numConfigurableKeys = 0 }} },
  [06] = { configurableKeys = { { } } },
  [07] = { configurableKeys = { { keyboardLayout = "QWERTY", numConfigurableKeys = nil }} },
  [08] = { configurableKeys = { { keyboardLayout = nil, numConfigurableKeys = 0 }} },
  [09] = { configurableKeys = common.getArrayValue({ { keyboardLayout = "QWERTY", numConfigurableKeys = 0 }}, 1001) }
}

--[[ Local Functions ]]
local function getDispCaps(pTC)
  local dispCaps = common.getDispCaps()
  dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = pTC
  return dispCaps
end

local function check(_, data)
  if data.payload.systemCapability ~= nil then
    return false, "Unexpected 'systemCapability' parameter received"
  end
  return true
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
  common.Step("HMI sends OnSCU", common.sendOnSCU, { dispCaps, common.expected.no })
  common.Step("App sends GetSC", common.sendGetSC, { { }, common.result.data_not_available, check })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
