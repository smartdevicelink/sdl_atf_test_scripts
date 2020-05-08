---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL rejects request with "INVALID_DATA" if app tries to send Show RPC to window in request
-- (invalid data type, missing mandatory params, etc.)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered and activated
-- 3) App successfully created a widget
-- 4) Widget is activated on the HMI and has FULL level
-- Steps:
-- 1) App send Show to Widget request with invalid WindowID type to SDL
-- SDL does:
--  - send Show response with (success = false, resultCode = INVALID_DATA") to App
--  - not send UI.Show request to HMI
--  - not send OnSystemCapabilityUpdated notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = "Widget",
  type = "WIDGET"
}

local invalidIDType = {
  "String", -- invalid type
  ""        -- empty value
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Success create Window", common.createWindow, { params })
common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { params.windowID})

common.Title("Test")
for _, value in pairs(invalidIDType) do
  common.Step("Show RPC to Window invalid ID data: ".. value, common.sendShowToWindowUnsuccess,
    { value, "INVALID_DATA" })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
