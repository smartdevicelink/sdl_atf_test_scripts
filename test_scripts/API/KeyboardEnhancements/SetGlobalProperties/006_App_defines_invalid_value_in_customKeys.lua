----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App receives 'INVALID_DATA' in case it defines invalid value for 'customKeys'
-- parameter of 'KeyboardProperties' struct
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with invalid value in 'customKeys' parameter in 'KeyboardProperties'
-- SDL does:
--  - Not transfer request to HMI
--  - Respond with INVALID_DATA, success:false to App
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
  [01] = { customKeys = common.json.EMPTY_ARRAY },        -- lower out of bound
  [02] = { customKeys = common.getArrayValue(keys, 9) },  -- upper out of bound
  [03] = { customKeys = 123 },                            -- invalid type
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
    { getSGPParams(data), common.result.invalid_data })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
