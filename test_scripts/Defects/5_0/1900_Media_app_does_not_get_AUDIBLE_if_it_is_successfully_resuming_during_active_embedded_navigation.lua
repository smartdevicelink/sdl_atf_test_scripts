---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1900
--
-- Description:
-- Media app does not get AUDIBLE if it's successfully resuming during active embedded navigation
-- Precondition:
-- SDL and HMI are started.
-- In case:
-- 1) Media app registers during active embedded navigation and satisfies all conditions for HMILevel resumption.
-- Expected result:
-- 1) SDL must set AUDIBLE audioStreamingState to this media app
-- and send via OnHMIStatus together with resumed HMILevel (FULL or LIMITED).
-- Actual result:
-- SDL does not resume HMILevel and audioStreamingState.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local connect = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function cleanSessions()
    for i = 1, common.getAppsCount() do
        connect.mobileSession[i] = nil
    end
end

local function unexpectedDisconnect()
    common.getMobileSession():Stop()
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = true })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        cleanSessions()
    end)
end

local function embeddedNaviSource()
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { eventName = "EMBEDDED_NAVI", isActive = true })
end

local function checkResumingMediaApp()
    common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp",
    {appID = common.getHMIAppId()})
    :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { eventName = "EMBEDDED_NAVI", isActive = false })
    common.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Unexpected disconnect app", unexpectedDisconnect)
runner.Step("Active embedded navigation", embeddedNaviSource)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("checkResumingActivationApp", checkResumingMediaApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
