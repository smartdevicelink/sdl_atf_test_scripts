---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3868
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL transfers succeed result code in error structure from HMI to the mobile app
-- during processing of CreateWindow

-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered and activated
-- 3. Policy Table Update is performed and "WidgetSupport" functional group is assigned for the app
--
-- Steps:
-- 1. Mobile app requests CreateWindow RPC
-- 2. SDL sends UI.CreateWindow request to the HMI
-- 3. HMI responds with succeed result code in error structure to UI.CreateWindow
--
-- SDL does:
-- - send CreateWindow(success = true, resultCode = <code received from HMI>) response to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3868/common_3868')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Policy Table Update", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
for windowId, resultCode in ipairs(common.tcs) do
  local response = { code = resultCode, structure = common.responsesStructures.error }
  common.Title("Test case: '" .. tostring(resultCode) .. "'" )
  common.Step("App sends CreateWindow RPC", common.createWindow,{ windowId, response })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

