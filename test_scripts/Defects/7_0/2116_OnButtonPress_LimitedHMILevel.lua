---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/2116
-- 
-- Steps:
-- 1) Start Core and HMI
-- 2) Connect mobile app to Core
-- 3) Mobile app subscribes to OnButtonPress and OnButtonEvent
-- 4) Mobile app goes to HMI level LIMITED
-- 5) HMI Sends OnButtonPress and OnButtonEvent specifying the appID of mobile app
-- 6) Mobile app should receive both OnButtonPress and OnButtonEvent
-- 7) HMI Sends OnButtonPress and OnButtonEvent without specifying the appID of mobile app
-- 8) Mobile app should not receive either OnButtonPress or OnButtonEvent
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "Test Application", appID = "0001",  fullAppID = "0000001" }
}

local function receiveButtonPressWithAppId()
  local mobSession1 = common.mobile.getSession()

  common.hmi.getConnection():SendNotification("Buttons.OnButtonEvent", {name = "OK", mode = "BUTTONDOWN", appID = common.app.getHMIId(1) })
  mobSession1:ExpectNotification("OnButtonEvent",{buttonName = "OK", buttonEventMode="BUTTONDOWN"})
  common.hmi.getConnection():SendNotification("Buttons.OnButtonPress", {name = "OK", mode = "LONG", appID = common.app.getHMIId(1)})
  mobSession1:ExpectNotification("OnButtonPress",{buttonName = "OK", buttonPressMode = "LONG"})
end

local function receiveButtonPressWithoutAppId()
    local mobSession1 = common.mobile.getSession()
  
    common.hmi.getConnection():SendNotification("Buttons.OnButtonEvent", {name = "OK", mode = "BUTTONDOWN"})
    mobSession1:ExpectNotification("OnButtonEvent",{buttonName = "OK", buttonEventMode="BUTTONDOWN"}):Times(0)
    common.hmi.getConnection():SendNotification("Buttons.OnButtonPress", {name = "OK", mode = "LONG"})
    mobSession1:ExpectNotification("OnButtonPress",{buttonName = "OK", buttonPressMode = "LONG"}):Times(0)
  end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect mobile device to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Activate App 1", common.app.activate, { 1 })
runner.Step("App1 from Mobile 1 requests Subscribe on OK", common.subscribeOnButton, {1, "OK", "SUCCESS" })
runner.Step("Send App 1 to LIMITED HMI level", common.hmiLeveltoLimited, { 1 })

runner.Title("Test")
runner.Step("HMI send OnButtonEvent and OnButtonPress with appID", receiveButtonPressWithAppId)
runner.Step("HMI send OnButtonEvent and OnButtonPress without appID", receiveButtonPressWithoutAppId)

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
