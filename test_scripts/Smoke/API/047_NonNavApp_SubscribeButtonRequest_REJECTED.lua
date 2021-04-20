---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: Navigation SubscribeButton
-- Item: Happy path
--
-- Requirement summary:
-- [SubscribeButton] SUCCESS: getting SUCCESS:SubscribeButton()
--
-- Description:
-- Mobile application sends valid SubscribeButton request and gets SubscribeButton "SUCCESS" response from SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. appID is a navigation type app

-- Steps:
-- appID requests Navigation SubscribeButton with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if Buttons interface is available on HMI
-- SDL checks if SubscribeButton is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL sends the Buttons notificaton to HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local buttonName = {
  "NAV_CENTER_LOCATION",
  "NAV_ZOOM_IN",
  "NAV_ZOOM_OUT",
  "NAV_PAN_UP",
  "NAV_PAN_UP_RIGHT",
  "NAV_PAN_RIGHT",
  "NAV_PAN_DOWN_RIGHT",
  "NAV_PAN_DOWN",
  "NAV_PAN_DOWN_LEFT",
  "NAV_PAN_LEFT",
  "NAV_PAN_UP_LEFT",
  "NAV_TILT_TOGGLE",
  "NAV_ROTATE_CLOCKWISE",
  "NAV_ROTATE_COUNTERCLOCKWISE",
  "NAV_HEADING_TOGGLE"
}

--[[ Local Functions ]]
local function subscribeButton(pButName)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("SubscribeButton", { buttonName = pButName })
  local appIDvalue = common.getHMIAppId()
  common.getHMIConnection():ExpectNotification("Buttons.OnButtonSubscription",
      { appID = appIDvalue, name = pButName, isSubscribed = true }):Times(0)
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, v in pairs(buttonName) do
  runner.Step("SubscribeButton " .. v .. " Rejected Case", subscribeButton, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
