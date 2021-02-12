----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL correctly proceed with 'SetGlobalProperties' requests
-- with 'KeyboardProperties' parameters for multiple apps
--
-- Steps:
-- 1. App_1 and App_2 are registered
-- 2. HMI provides two different sets of 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notifications
-- to App_1 and to App_2
-- 3. App_1 sends 'SetGlobalProperties' with 'KeyboardProperties' which are corresponds to App_1
-- SDL does:
--  - Proceed with request successfully
-- 4. App_1 sends 'SetGlobalProperties' with 'KeyboardProperties' which are corresponds to App_2
-- SDL does:
--  - Not proceed with request and respond with INVALID_DATA, success:false to App
-- 5. App_2 sends 'SetGlobalProperties' with 'KeyboardProperties' which are corresponds to App_2
-- SDL does:
--  - Proceed with request successfully
-- 6. App_2 sends 'SetGlobalProperties' with 'KeyboardProperties' which are corresponds to App_1
-- SDL does:
--  - Not proceed with request and respond with INVALID_DATA, success:false to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local dispCaps1 = common.getDispCaps()
dispCaps1.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
  maskInputCharactersSupported = true,
  supportedKeyboards = { { keyboardLayout = "AZERTY", numConfigurableKeys = 2 } }
}
local dispCaps2 = common.getDispCaps()
dispCaps2.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
  maskInputCharactersSupported = false,
  supportedKeyboards = { { keyboardLayout = "NUMERIC", numConfigurableKeys = 1 } }
}

--[[ Local Functions ]]
local function getSGPParams(pLayout, pNumOfKeys)
  local keys = { "$", "#", "&" }
  return {
    keyboardProperties = {
      keyboardLayout = pLayout,
      customKeys = common.getArrayValue(keys, pNumOfKeys)
    }
  }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU, { 1 })
common.Step("Register App", common.registerAppWOPTU, { 2 })

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated for App 1", common.sendOnSystemCapabilityUpdated,
  { dispCaps1, nil, nil, 1 })
common.Step("HMI sends OnSystemCapabilityUpdated for App 2", common.sendOnSystemCapabilityUpdated,
  { dispCaps2, nil, nil, 2 })

common.Title("App 1")
common.Step("App 1 sends SetGlobalProperties valid", common.sendSetGlobalProperties,
  { getSGPParams("AZERTY", 1), common.result.success, nil, 1 })
common.Step("App 1 sends SetGlobalProperties valid", common.sendSetGlobalProperties,
  { getSGPParams("AZERTY", 2), common.result.success, nil, 1 })
common.Step("App 1 sends SetGlobalProperties invalid", common.sendSetGlobalProperties,
  { getSGPParams("AZERTY", 3), common.result.invalid_data, nil, 1 })
common.Step("App 1 sends SetGlobalProperties invalid", common.sendSetGlobalProperties,
  { getSGPParams("NUMERIC", 1), common.result.invalid_data, nil, 1 })

common.Title("App 2")
common.Step("App 2 sends SetGlobalProperties valid", common.sendSetGlobalProperties,
  { getSGPParams("NUMERIC", 1), common.result.success, nil, 2 })
common.Step("App 2 sends SetGlobalProperties invalid", common.sendSetGlobalProperties,
  { getSGPParams("NUMERIC", 2), common.result.invalid_data, nil, 2 })
common.Step("App 2 sends SetGlobalProperties invalid", common.sendSetGlobalProperties,
  { getSGPParams("AZERTY", 1), common.result.invalid_data, nil, 2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
