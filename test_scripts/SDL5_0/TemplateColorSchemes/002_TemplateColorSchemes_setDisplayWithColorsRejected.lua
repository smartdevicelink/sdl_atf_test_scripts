---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0147-template-color-scheme.md
--
-- Description:
-- SDL Core should track the number of attempted SetDisplayLayout requests with the current template and REJECT
-- any beyond the first with the reason "Using SetDisplayLayout to change the color scheme may only be done once.
--
-- Preconditions: Send SetDisplayLayout with a layout and a color scheme.
--
-- Steps: Send additional SetDisplayLayout with same layout but use a different color scheme
--
-- Expected result:
-- SDL Core returns REJECTED
-- Note: since "SetDisplayLayout" is deprecated SDL has to respond with WARNINGS to mobile in success case
---------------------------------------------------------------------------------------------------


--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local function getRequestParams()
  return {
    displayLayout = "ONSCREEN_PRESETS",
    dayColorScheme = {
      primaryColor = {
        red = 0,
        green = 255,
        blue = 100
      }
    }
  }
end

local function getRequestParams2()
  return {
    displayLayout = "ONSCREEN_PRESETS",
    dayColorScheme = {
      primaryColor = {
        red = 0,
        green = 0,
        blue = 0
      }
    }
  }
end

local function setDisplayWithColorsSuccess()
  local responseParams = {}
  local cid = commonSmoke.getMobileSession():SendRPC("SetDisplayLayout", getRequestParams())
  EXPECT_HMICALL("UI.SetDisplayLayout", getRequestParams())
  :Do(function(_, data)
    commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseParams)
  end)
  commonSmoke.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "WARNINGS"
  })
end

local function setDisplayWithColorsRejected()
  local responseParams = {}
  local cid = commonSmoke.getMobileSession():SendRPC("SetDisplayLayout", getRequestParams2())
  commonSmoke.getMobileSession():ExpectResponse(cid, {
    success = false,
    resultCode = "REJECTED"
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("SetDisplay Positive Case 1", setDisplayWithColorsSuccess)
runner.Step("SetDisplay Rejected Case", setDisplayWithColorsRejected)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
