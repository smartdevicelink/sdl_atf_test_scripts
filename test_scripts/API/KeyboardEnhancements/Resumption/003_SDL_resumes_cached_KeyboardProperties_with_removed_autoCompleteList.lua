----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to resume cached language, keyboardLayout from KeyboardProperties
-- after unexpected disconnect
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with some non-default values for all parameters in 'KeyboardProperties'
-- SDL does:
--  - Cache all values of received parameters
-- 4. App sends 'SetGlobalProperties' with empty array in autoCompleteList in 'KeyboardProperties'
-- SDL does:
--  - Keep values for language, keyboardLayout
--  - Reset all other parameter values to the default values
-- 5. App unexpectedly disconnects and reconnects
-- SDL does:
--  - Start data resumption process
--  - Send language, keyboardLayout defined by App in 'KeyboardProperties' to HMI
--   within 'UI.SetGlobalProperties' request
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local sgpParams_1 = {
  keyboardProperties = {
    language = "EN-US",
    keyboardLayout = "AZERTY",
    keypressMode = "SINGLE_KEYPRESS",
    limitedCharacterList = { "a" },
    autoCompleteList = { "Daemon, Freedom" },
    maskInputCharacters = "DISABLE_INPUT_KEY_MASK",
    customKeys = { "#", "$" }
  }
}

local sgpParams_2 = {
  keyboardProperties = {
    autoCompleteList = common.json.EMPTY_ARRAY
  }
}

local sgpParams_resumption = {
  keyboardProperties = {
    language = sgpParams_1.keyboardProperties.language,
    keyboardLayout = sgpParams_1.keyboardProperties.keyboardLayout
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated)
common.Step("App sends SetGlobalProperties first request", common.sendSetGlobalPropertiesWithHashId,
  { sgpParams_1, common.result.success })
common.Step("App sends SetGlobalProperties second request", common.sendSetGlobalPropertiesWithHashId,
  { sgpParams_2, common.result.success })
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App", common.reRegisterApp, { sgpParams_resumption })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
