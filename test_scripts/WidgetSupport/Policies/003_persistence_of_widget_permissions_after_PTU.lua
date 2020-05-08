---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL persists widget app permissions after PTU
--
-- Preconditions:
-- 1) "WidgetSupport" functional group is initially assigned for the app by policies
-- 2) SDL and HMI are started, App is registered
-- Steps:
-- 1) App tries to create a widget by sending "CreateWindow" request
-- SDL does proceed with request successfully
-- 2) Policy Table Update is performed and "WidgetSupport" functional group is re-assigned for the app
-- 3) App tries to create another widget by sending "CreateWindow" request
-- SDL does proceed with request successfully
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local widgetParams1 = {
  windowID = 1,
  windowName = "Widget1",
  type = "WIDGET"
}

local widgetParams2 = {
  windowID = 2,
  windowName = "Widget2",
  type = "WIDGET"
}

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "Base-4", "WidgetSupport" }
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerApp)

common.Title("Test")
common.Step("App creates a widget 1 SUCCESS", common.createWindow, { widgetParams1 })
common.Step("Policy Table Update incl. WidgetSupport func. group", common.policyTableUpdate, { ptUpdate })
common.Step("App creates a widget 2 SUCCESS", common.createWindow, { widgetParams2 })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
