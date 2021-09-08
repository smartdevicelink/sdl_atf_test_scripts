---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/3768
---------------------------------------------------------------------------------------------------
-- Description:
-- When activating a media app via VR, once Core processes the VR Stopped event,
-- if there is no other media source playing, mobile should receive OnHMIStatus(FULL, AUDIBLE)
--
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Variables ]]

--[[ Local Functions ]]
local function activateAppExpectAudible()
  common.getHMIConnection():SendNotification("VR.Started")

  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(1) })
  common.getHMIConnection():ExpectResponse(requestId)

  common.getHMIConnection():SendNotification("VR.Stopped")

  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" }
  ):Times(2)
end

local function sendAlertExpectAudible()
  common.getMobileSession(1):SendRPC("Alert", {
      alertText1 = "alert"
  })

  common.getHMIConnection():ExpectRequest("UI.Alert", {})
  :Do(function(_, data)
    common.getHMIConnection():SendNotification("UI.OnSystemContext", {
        appID = common.getHMIAppId(),
        systemContext = "ALERT"
    })

    local function alertResponse()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      common.getHMIConnection():SendNotification("UI.OnSystemContext", {
        appID = common.getHMIAppId(),
        systemContext = "MAIN"
      })
    end

    common.run.runAfter(alertResponse, 3000)
  end)

  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" }
  )
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Create mobile connection and session", common.start)
runner.Step("Register Media App", common.registerAppWOPTU, { 1 })

runner.Title("Test")
runner.Step("Activate App via VR, expect AUDIBLE", activateAppExpectAudible)
runner.Step("Send ALERT, expect AUDIBLE", sendAlertExpectAudible)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
