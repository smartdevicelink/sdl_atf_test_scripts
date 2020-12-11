----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App receives 'INVALID_DATA' if number of keys in 'customizeKeys' array is more
-- than customizable keys allowed
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
-- 3. App sends 'SetGlobalProperties' with excessive number of values in 'customizeKeys' parameter
-- in 'KeyboardProperties'
-- SDL does:
--  - Not transfer request to HMI
--  - Respond with INVALID_DATA, success:false to App with appropriate message in 'info'
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local keys = { "$", "#", "&" }

--[[ Local Functions ]]
local function getOnSCUParams(pNumOfKeys)
  local dispCaps = common.getDispCaps()
  dispCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].keyboardCapabilities = {
    supportedKeyboardLayouts = { "NUMERIC" },
    configurableKeys = { { keyboardLayout = "NUMERIC", numConfigurableKeys = pNumOfKeys } }
  }
  return dispCaps
end

local function getSGPParams(pNumOfKeys, pLayout)
  if not pLayout then pLayout = "NUMERIC" end
  return {
    keyboardProperties = {
      keyboardLayout = pLayout,
      customizeKeys = common.getArrayValue(keys, pNumOfKeys)
    }
  }
end

local function check(_, data)
  if data.payload.success == true and data.payload.info ~= nil then
    return false, "Unexpected 'info' parameter received"
  end
  local exp = "customizeKeys exceeds the number of customizable keys in this Layout"
  if data.payload.success == false and data.payload.info ~= exp then
    return false, "Expected 'info':\n" .. exp .. "\nActual:\n" .. tostring(data.payload.info)
  end
  return true
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSCU 1", common.sendOnSCU, { getOnSCUParams(1) })
common.Step("App sends SetGP 1 success", common.sendSetGP,
  { getSGPParams(1), common.result.success, check })
common.Step("App sends SetGP 2 invalid_data", common.sendSetGP,
  { getSGPParams(2), common.result.invalid_data, check })
common.Step("HMI sends OnSCU 1", common.sendOnSCU, { getOnSCUParams(2) })
common.Step("App sends SetGP 1 success", common.sendSetGP,
  { getSGPParams(1), common.result.success, check })
common.Step("App sends SetGP 2 success", common.sendSetGP,
  { getSGPParams(2), common.result.success, check })
common.Step("App sends SetGP 3 invalid_data", common.sendSetGP,
  { getSGPParams(3), common.result.invalid_data, check })
common.Step("App sends SetGP 1 unknown layout invalid_data", common.sendSetGP,
  { getSGPParams(1, "QWERTY"), common.result.invalid_data, check })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
