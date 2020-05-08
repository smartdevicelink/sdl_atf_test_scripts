---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description:Check SDL rejects request with "INVALID_DATA" if app tries to delete a window with invalid data
--  in request (invalid data type, missing mandatory params, etc.)
--
-- Precondition:
-- 1) SDL and HMI are started and MAIN window created during HMI started
-- 2) CreateWindow and DeleteWindow are allowed by policies
-- 3) App is registered
-- 4) App successfully created a widget
-- Steps:
-- 1) App send DeleteWindow request with invalid WindowID type to SDL
-- SDL does:
--  - send DeleteWindow response with (success = false, resultCode = INVALID_DATA") to App
--  - not send UI.DeleteWindow(WindowID) request to HMI
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
common.Step("Success create Window", common.createWindow, { params })

common.Title("Test")
for _, value in pairs(invalidIDType) do
  common.Step("Delete Widget, invalid ID data: ".. value,
    common.deleteWindowUnsuccess, { value, "INVALID_DATA" })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
