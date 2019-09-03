---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL rejects request with "INVALID_DATA" if app tries to create a window with invalid data
--  in request (invalid data type, missing mandatory params, etc.)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered
-- Step:
-- 1) App sends CreateWindow request with invalid params to SDL:
--  a) invalid type
--  b) empty value
--  c) missing mandatory
-- SDL does:
--  - not send request to HMI
--  - send CreateWindow response with success:false, resultCode:"INVALID_DATA" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local pInvalidParams = {
  missingWindowID = { windowName = "Name1", type = "WIDGET" },
  invaidTypeWindowID = { windowID = "2", windowName = "Name1", type = "WIDGET" },
  emptyValueWindowID = { windowID = "", windowName = "Name1", type = "WIDGET" },

  missingWindowName = { windowID = 2, type = "WIDGET" },
  invaidTypeWindowName = { windowID = 2, windowName = 1234, type = "WIDGET" },
  emptyValueWindowName = { windowID = 2, windowName = "", type = "WIDGET" },

  missingType = { windowID = 2, windowName = "Name1" },
  invaidValueType = { windowID = 2, windowName = "Name1", type = 1234 },
  emptyValueType = { windowID = 2, windowName = "", type = "" }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)

common.Title("Test")
for k, v in pairs(pInvalidParams) do
  common.Step("App sends CreateWindow request with " .. k,
    common.createWindowUnsuccess, { v, "INVALID_DATA" })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
