----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to reset previously defined 'KeyboardProperties' to default values
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with some non-default values for 'KeyboardProperties'
-- 4. App sends 'ResetGlobalProperties' for 'KEYBOARDPROPERTIES'
-- SDL does:
--  - Send default values for 'KeyboardProperties' to HMI within 'UI.SetGlobalProperties' request
--  - By receiving successful response from HMI transfer it to App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local sgpParams = {
  keyboardProperties = {
    language = "EN-US",
    keyboardLayout = "NUMERIC",
    keypressMode = "SINGLE_KEYPRESS",
    limitedCharacterList = { "a" },
    autoCompleteList = { "Daemon, Freedom" },
    maskInputCharacters = "DISABLE_INPUT_KEY_MASK",
    customKeys = { "#" }
  }
}

--[[ Local Functions ]]
local function sendResetGP()
  local params = { properties = { "KEYBOARDPROPERTIES" } }
  local dataToHMI = {
    keyboardProperties = {
      language = "EN-US",
      keyboardLayout = "QWERTY",
      autoCompleteList = common.json.EMPTY_ARRAY,
      maskInputCharacters = "DISABLE_INPUT_KEY_MASK"
    },
    appID = common.getHMIAppId()
  }
  local cid = common.getMobileSession():SendRPC("ResetGlobalProperties", params)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_, data)
      if data.params.keyboardProperties.customKeys then
        return false, "Unexpected 'customKeys' parameter received"
      end
      return true
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated)
common.Step("App sends SetGlobalProperties", common.sendSetGlobalProperties, { sgpParams, common.result.success })
common.Step("App sends ResetGP", sendResetGP)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
