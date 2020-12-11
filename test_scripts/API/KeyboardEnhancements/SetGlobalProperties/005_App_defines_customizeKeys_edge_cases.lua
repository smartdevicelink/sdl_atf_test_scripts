----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to change special characters via 'customizeKeys' parameter
-- of 'KeyboardProperties' struct (edge scenarios)
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with 'customizeKeys' in 'KeyboardProperties'
-- SDL does:
--  - Proceed with request successfully
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local dispCaps = common.getDispCaps()
dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
  supportedKeyboardLayouts = { "NUMERIC" },
  configurableKeys = { { keyboardLayout = "NUMERIC", numConfigurableKeys = 11 } }
}

local keys = { "$", "#", "&" }

local tcs = {
  [01] = { customizeKeys = common.getArrayValue(keys, 1) }, -- lower in bound
  [02] = { customizeKeys = common.getArrayValue(keys, 10) } -- upper in bound
}

--[[ Local Functions ]]
local function getSGPParams(pKeys)
  return {
    keyboardProperties = {
      keyboardLayout = "NUMERIC",
      customizeKeys = pKeys.customizeKeys
    }
  }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSCU", common.sendOnSCU, { dispCaps })
for tc, data in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  common.Step("App sends SetGP", common.sendSetGP, { getSGPParams(data), common.result.success })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
