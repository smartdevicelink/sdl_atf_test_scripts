----------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0238-Keyboard-Enhancements.md
----------------------------------------------------------------------------------------------------
-- Description: Check App receives 'INVALID_DATA' if number of keys in 'customKeys' array is more
-- than customizable keys allowed.
-- Scenario with a few consecutive 'SetGlobalProperties' requests
--
-- Steps:
-- 1. App is registered
-- 2. HMI provides 'KeyboardCapabilities' within 'OnSystemCapabilityUpdated' notification
--  where 'numConfigurableKeys=1' for 'NUMERIC'
-- 3. App sends 'SetGlobalProperties' with 'keyboardLayout=NUMERIC' in 'KeyboardProperties'
-- SDL does:
--  - Proceed with request successfully
-- 4. App sends 'SetGlobalProperties' with 'customKeys=<1 element>' in 'KeyboardProperties'
-- SDL does:
--  - Proceed with request successfully
-- 5. App sends 'SetGlobalProperties' with 'customKeys=<2 elements>' in 'KeyboardProperties'
-- SDL does:
--  - Not transfer request to HMI
--  - Respond with INVALID_DATA, success:false to App with appropriate message in 'info'
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/KeyboardEnhancements/common')

--[[ Local Variables ]]
local params1 = {
  keyboardProperties = {
    keyboardLayout = "NUMERIC",
  }
}

local params2 = {
  keyboardProperties = {
    customKeys = { "$" }
  }
}

local params3 = {
  keyboardProperties = {
    customKeys = { "$", "#" }
  }
}


--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("HMI sends OnSystemCapabilityUpdated", common.sendOnSystemCapabilityUpdated)
common.Step("App sends SetGlobalProperties success", common.sendSetGlobalProperties, { params1, common.result.success })
common.Step("App sends SetGlobalProperties success", common.sendSetGlobalProperties, { params2, common.result.success })
common.Step("App sends SetGlobalProperties invalid_data", common.sendSetGlobalProperties,
  { params3, common.result.invalid_data })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
