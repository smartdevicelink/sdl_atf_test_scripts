----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to change special characters via 'customKeys' parameter
-- of 'KeyboardProperties' struct (edge scenarios)
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with 'customKeys' in 'KeyboardProperties'
-- SDL does:
--  - Proceed with request successfully
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local dispCaps = common.getDispCaps()
dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
  supportedKeyboards = { { keyboardLayout = "NUMERIC", numConfigurableKeys = 8 } }
}

local keys = { "$", "#", "&" }

local tcs = {
  [01] = { customKeys = common.getArrayValue(keys, 1) }, -- lower in bound
  [02] = { customKeys = common.getArrayValue(keys, 8) } -- upper in bound
}

--[[ Local Functions ]]
local function getSGPParams(pKeys)
  return {
    keyboardProperties = {
      keyboardLayout = "NUMERIC",
      customKeys = pKeys.customKeys
    }
  }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { dispCaps })
for tc, data in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  common.Step("App sends SetGlobalProperties", common.sendSetGlobalProperties,
    { getSGPParams(data), common.result.success })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
