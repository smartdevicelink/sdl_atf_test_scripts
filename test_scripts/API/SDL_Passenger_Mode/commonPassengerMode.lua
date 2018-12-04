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

--[[ @ptuFunc: Update PT
--! @parameters:
--! pTbl - table for update
--! @return: none
--]]
function c.ptuFunc(pTbl)
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.OnDriverDistraction.hmi_levels = { "FULL", "LIMITED", "BACKGROUND" }
end

--[[ @registerApp: register mobile application
--! @parameters: none
--! @return: none
--]]
function c.registerApp()
  c.getMobileSession():StartService(7)
  :Do(function()
    local corId = c.getMobileSession():SendRPC("RegisterAppInterface", c.getConfigAppParams())
    c.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = c.getConfigAppParams().appName } })
    :Do(function(_, d1)
      c.setHMIAppId(d1.params.application.appID)
        c.getHMIConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
        :Do(function(_, d2)
          c.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", { })
        end)
    end)
    c.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      c.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })

      c.getMobileSession():ExpectNotification("OnPermissionsChange")
      :Times(AnyNumber())

      c.getMobileSession():ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
    end)
  end)
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
