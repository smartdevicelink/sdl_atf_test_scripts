----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is unable to set 'keyboardProperties' for unsupported 'keyboardLayout'.
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- with supported keyboards in 'supportedKeyboards'
-- 3. App sends 'SetGlobalProperties' with 'keyboardLayout' in 'KeyboardProperties' which is not
-- in 'supportedKeyboards' list
-- SDL does:
--  - Transfer request to HMI
-- 4. HMI responds with erroneous 'UNSUPPORTED_RESOURCE' message
-- SDL does:
--  - Respond with 'UNSUPPORTED_RESOURCE', success:false to App with appropriate message in 'info'
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local msg = "keyboard layout is not supported"
local dispCaps = common.getDispCaps()
dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
  supportedKeyboards = { { keyboardLayout = "NUMERIC", numConfigurableKeys = 1 } }
}

--[[ Local Functions ]]
local function sendSetGlobalProperties()
  local sgpParams = {
    keyboardProperties = {
      keyboardLayout = "QWERTY",
      keypressMode = "SINGLE_KEYPRESS"
    }
  }
  local dataToHMI = common.cloneTable(sgpParams)
  dataToHMI.appID = common.getHMIAppId()
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", sgpParams)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", msg)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE", info = msg })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated, { dispCaps })
common.Step("App sends SetGlobalProperties warnings", sendSetGlobalProperties)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
