---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL respond with "INVALID_DATA" if an app tries to create a widget
-- with associatedServiceType param with invalid data in request (invalid data type, empty)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow is allowed by policies
-- 3) App is registered
-- Step:
-- 1) App sends CreateWindow request with invalid associatedServiceType param to SDL:
--  a) invalid type
--  b) empty value
-- SDL does:
--  - not send request to HMI
--  - send CreateWindow response with success:false, resultCode:"INVALID_DATA" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local pInvalidParam = {
  invaidTypeServiceType = { windowID = 1, windowName = "Name1", type = "WIDGET", associatedServiceType = 123 },
  emptyValueServiceType = { windowID = 1, windowName = "Name2", type = "WIDGET", associatedServiceType = "" }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)

common.Title("Test")
for k, v in pairs(pInvalidParam) do
  common.Step("App sends CreateWindow request with " .. k,
  common.createWindowUnsuccess, { v, "INVALID_DATA" })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
