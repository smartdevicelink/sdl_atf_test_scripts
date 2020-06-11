---------------------------------------------------------------------------------------------------
-- Description:
-- Mobile sends an unknown enum included in a param that is a struct. Because the enum is
-- mandatory inside the struct, the entire struct param will be removed so the message can pass.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- appID requests SetMediaClockTimer with an unknown updateMode enum

-- Expected:
-- SDL Core filters out the unknown enum. The HMI receives the request without the containing struct.
-- WARNINGS result is returned to mobile.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  keyboardProperties = {
    autoCompleteList = { "Daemon" , "Freedom" }
  },
  menuIcon = {
    value = "img.jpg",
    imageType = "UNKNOWN"
  }
}

local requestUiParams = {
  keyboardProperties = requestParams.keyboardProperties
}

local function SetGlobalPropertiesUnknownMenuIcon()
  local mobileSession = commonSmoke.getMobileSession(1)
  local cid = mobileSession:SendRPC("SetGlobalProperties", requestParams)

  requestUiParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("UI.SetGlobalProperties", requestUiParams)
  :Do(function(_,data)
      commonSmoke.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end):ValidIf(function(_, data)
    return data.params["menuIcon"] == nil
  end)

  mobileSession:ExpectResponse(cid, {
    success = true,
    resultCode = "WARNINGS"
  }):ValidIf(function(_, data)
    return string.match(data.payload.info, "imageType")
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("Send Unknown Enum in Param Structure", SetGlobalPropertiesUnknownMenuIcon)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
