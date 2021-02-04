----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to change special characters via 'customKeys' parameter
-- of 'KeyboardProperties' struct
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
local keys = { "$", "#", "&" }

--[[ Local Functions ]]
local function getSGPParams(pKey)
  return {
    keyboardProperties = {
      keyboardLayout = "NUMERIC",
      customKeys = { pKey }
    }
  }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated)
for _, v in common.spairs(keys) do
  common.Step("App sends SetGlobalProperties", common.sendSetGlobalProperties,
    { getSGPParams(v), common.result.success })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
