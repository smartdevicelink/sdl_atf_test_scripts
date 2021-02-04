----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to resume cached and set parameters from KeyboardProperties
-- after unexpected disconnect
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with some non-default values for all parameters in 'KeyboardProperties'
-- SDL does:
--  - Cache all values of received parameters
-- 4. App sends 'SetGlobalProperties' with one parameter in 'KeyboardProperties'
-- SDL does:
--  - Keep values for language, keyboardLayout, autoCompleteList
--  - Reset all other parameter values to the default values
--  - Update the value of parameter received in the second SetGlobalProperties request
-- 5. App unexpectedly disconnects and reconnects
-- SDL does:
--  - Start data resumption process
--  - Send cached and set parameters defined by App in 'KeyboardProperties' to HMI
--   within 'UI.SetGlobalProperties' request
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local sgpParams = {
  keyboardProperties = {
    language = "DE-DE",
    keyboardLayout = "NUMERIC",
    keypressMode = "QUEUE_KEYPRESSES",
    limitedCharacterList = { "b" },
    autoCompleteList = { "123" },
    maskInputCharacters = "ENABLE_INPUT_KEY_MASK",
    customKeys = { "*" }
  }
}

--[[ Local Functions ]]
local function getParamsForReq(pParam)
  local reqParams = {
    keyboardProperties = {
      language = "EN-US",
      keyboardLayout = "AZERTY",
      keypressMode = "SINGLE_KEYPRESS",
      limitedCharacterList = { "a" },
      autoCompleteList = { "Daemon, Freedom" },
      maskInputCharacters = "DISABLE_INPUT_KEY_MASK",
      customKeys = { "#" }
    }
  }
  local out = {
    keyboardProperties = {}
  }
  out.keyboardProperties[pParam] = reqParams.keyboardProperties[pParam]
  return out
end

local function getResumptionParams(pReqParams)
  local resumptionParams = {
    keyboardProperties = {
      language = sgpParams.keyboardProperties.language,
      keyboardLayout = sgpParams.keyboardProperties.keyboardLayout,
      autoCompleteList = sgpParams.keyboardProperties.autoCompleteList
    }
  }
  local k, v = next(pReqParams.keyboardProperties)
  resumptionParams.keyboardProperties[k] = v
  return resumptionParams
end

--[[ Scenario ]]
for parameter in common.spairs (sgpParams.keyboardProperties) do
  common.Title("Resumption of " .. parameter .. " parameter")
  local reqParams = getParamsForReq(parameter)
  local resumptionParams = getResumptionParams(reqParams)
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerApp)

  common.Title("Test")
  common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated)
  common.Step("App sends SetGlobalProperties first request", common.sendSetGlobalPropertiesWithHashId,
    { sgpParams, common.result.success })
  common.Step("App sends SetGlobalProperties second request", common.sendSetGlobalPropertiesWithHashId,
    { reqParams, common.result.success })
  common.Step("Unexpected disconnect", common.unexpectedDisconnect)
  common.Step("Connect mobile", common.connectMobile)
  common.Step("Re-register App", common.reRegisterApp, { resumptionParams })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
