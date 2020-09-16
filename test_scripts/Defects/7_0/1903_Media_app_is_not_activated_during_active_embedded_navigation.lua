---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1903
--
-- Description:
-- Media app is not activated during active embedded navigation.
-- Precondition:
-- SDL and HMI are started. Media app is activated in HMI.
-- In case:
-- 1) HMI activates embedded navigation. Media app is moved to LIMITED and AUDIBLE state.
-- 2) SDL receives SDL.ActivateApp (<appID_of_media_app>) from HMI.
-- Expected result:
-- 1) SDL must respond SDL.ActivateApp (SUCCESS) to HMI
--    send OnHMIStatus (FULL, AUDIBLE) to mobile app (embedded navigation is still active).
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function embeddedNavigation()
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { eventName = "EMBEDDED_NAVI", isActive = true })

    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function activateMediaApp()
    local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
    common.getHMIConnection():ExpectResponse(requestId)
    :Do(function()
        common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
        { eventName = "EMBEDDED_NAVI", isActive = true })
    end)
    common.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Media app during active embedded audio source", embeddedNavigation)
runner.Step("Activate media app", activateMediaApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
