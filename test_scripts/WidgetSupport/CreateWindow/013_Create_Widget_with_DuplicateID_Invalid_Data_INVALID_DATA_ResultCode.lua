---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL rejects request with "INVALID_DATA" result code if app tries to create Widget
-- window with "duplicateUpdatesFromWindowID" (invalid data type, etc.) in request
--  ("templateConfiguration" param is not defined)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- Steps:
-- 1) App sends CreatedWindow widgets with "duplicateUpdatesFromWindowID" with invalid ID type to SDL
-- SDL does:
--  - send CreatedWindow response with (success = false, resultCode = "INVALID_DATA") to App
--  - not send UI.CreateWindow(params) request to HMI
--  - not send OnSystemCapabilityUpdated notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local pInvalidParams = {
  invalidTypeStringDuplicateWindowID = {
    windowID = 1,
    windowName = config.application1.registerAppInterfaceParams.appName,
    type = "WIDGET",
    duplicateUpdatesFromWindowID = "0"
  },
  invalidTypeTableDuplicateWindowID = {
    windowID = 1,
    windowName = config.application1.registerAppInterfaceParams.appName,
    type = "WIDGET",
    duplicateUpdatesFromWindowID = {}
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for k, value in pairs(pInvalidParams) do
  common.Step("App sends CreateWindow request for window with ".. k,
    common.createWindowUnsuccess, { value, "INVALID_DATA" })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
