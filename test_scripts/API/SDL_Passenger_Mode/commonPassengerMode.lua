---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Module ]]
local c = actions

--[[ Variables ]]

c.OnDDValue = { "DD_ON", "DD_OFF" }
c.value = { true, false }

--[[ Common Functions ]]

--[[ @registerApp: register mobile application
--! @parameters: none
--! @return: none
--]]
function c.registerApp()
  c.registerAppWOPTU()
  c.getMobileSession():ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
end

--[[ @deactivateAppToLimited: bring app to LIMITED HMI level
--! @parameters:none
--! @return: none
--]]
function c.deactivateAppToLimited()
  c.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = c.getHMIAppId() })
  c.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ @deactivateAppToBackground: bring app to BACKGROUND HMI level
--! @parameters:none
--! @return: none
--]]
function c.deactivateAppToBackground()
  c.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "AUDIO_SOURCE", isActive = true
  })
  c.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ @onDriverDistraction: Send OnDriverDistraction notification from HMI
--! @parameters:
--! pOnDDValue - value for state parameter
--! pValue - value for lockScreenDismissalEnabled parameter
--! @return: none
--]]
function c.onDriverDistraction(pOnDDValue, pValue)
  local request = { state = pOnDDValue, lockScreenDismissalEnabled = pValue }
  c.getHMIConnection():SendNotification("UI.OnDriverDistraction", request)
  c.getMobileSession():ExpectNotification("OnDriverDistraction", request)
end


--[[ @onDriverDistractionUnsuccess: Send OnDriverDistraction notification from HMI
--! @parameters:
--! pOnDDValue - value for state parameter
--! pValue - value for lockScreenDismissalEnabled parameter
--! @return: none
--]]
function c.onDriverDistractionUnsuccess(pOnDDValue, pValue)
  local request = { state = pOnDDValue, lockScreenDismissalEnabled = pValue }
  c.getHMIConnection():SendNotification("UI.OnDriverDistraction", { request })
  c.getMobileSession():ExpectNotification("OnDriverDistraction", { request })
  :Times(0)
end

return c
