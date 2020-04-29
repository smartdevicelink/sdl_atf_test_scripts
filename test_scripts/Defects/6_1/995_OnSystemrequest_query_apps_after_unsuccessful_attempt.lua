---------------------------------------------------------------------------------------------
-- Issue https://github.com/SmartDeviceLink/sdl_core/issues/995
---------------------------------------------------------------------------------------------
-- Preconditions:
-- 1. Core, HMI started.
-- 2. App is registered on HMI and has HMI level BACKGROUND

-- Steps to reproduce:
-- 1. Register app via 4th protocol.
-- 2. App sends incorrect json on SystemRequest and receives error code in response.
-- 3. Bring app to background and then to foreground again or register new app via 4th protocol.

-- Expected result:
-- SDL does not send OnSystemRequest(QUERY_APPS) to the same app after bringing it to foreground
-- and also to new registered app after unsuccessful attempt to send query json.
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 4 -- Set 4 protocol as default for script

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 4

--Sending OnHMIStatus notification form mobile application
local function SendingOnHMIStatusFromMobile(pAppId, pLevel)
  local sessionName = common.getMobileSession(pAppId)
  sessionName.correlationId = sessionName.correlationId + 100*pAppId
  local msg = {
      serviceType      = 7,
      frameInfo        = 0,
      rpcType          = 2,
      rpcFunctionId    = 32768,
      rpcCorrelationId = sessionName.correlationId,
      payload          = '{"hmiLevel" : "' .. tostring(pLevel) .. '"'
        .. ', "audioStreamingState" : "NOT_AUDIBLE"'
        .. ', "systemContext" : "MAIN"'
        .. ', "videoStreamingState" : "NOT_STREAMABLE"}'
    }
  sessionName:Send(msg)
  utils.cprint(33, "Sending OnHMIStatus from mobile app" .. pAppId .. " with level ".. tostring(pLevel))
end

local function OnSystemRequest_QueryApps_IsError()
  SendingOnHMIStatusFromMobile(1, "FULL")

  common.getMobileSession(1):ExpectNotification("OnSystemRequest", { requestType = "QUERY_APPS" })
  :Do(function()
      local cid = common.getMobileSession(1):SendRPC("SystemRequest", {
          requestType = "QUERY_APPS",
          fileName = "incorrectJSON.json"
        },
        "files/jsons/QUERRY_jsons/incorrectJSON.json")
      common.getMobileSession(1):ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
    end)
end

local function RegisterSecondApp()
  common.registerApp(2)
end

local function OnSystemRequest_QueryApps_IsNotSentToNewRegisteredApp()
  SendingOnHMIStatusFromMobile(1, "BACKGROUND")
  SendingOnHMIStatusFromMobile(2, "FULL")
  common.getMobileSession(2):ExpectNotification("OnSystemRequest", { requestType = "QUERY_APPS" })
  :Times(0)
  common.getMobileSession(1):ExpectNotification("OnSystemRequest", { requestType = "QUERY_APPS" })
  :Times(0)
end

local function OnSystemRequest_QueryApps_IsNotSentToTheSameAppInForeground()
  SendingOnHMIStatusFromMobile(2, "BACKGROUND")
  SendingOnHMIStatusFromMobile(1, "FULL")
  common.getMobileSession(2):ExpectNotification("OnSystemRequest", { requestType = "QUERY_APPS" })
  :Times(0)
  common.getMobileSession(1):ExpectNotification("OnSystemRequest", { requestType = "QUERY_APPS" })
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app1", common.registerAppWOPTU)
runner.Step("Activate app1", common.activateApp)

runner.Title("Test")
runner.Step("OnSystemRequest_QueryApps_IsError", OnSystemRequest_QueryApps_IsError)
runner.Step("Register app2", RegisterSecondApp)
runner.Step("OnSystemRequest_QueryApps_IsNotSentToNewRegisteredApp",
  OnSystemRequest_QueryApps_IsNotSentToNewRegisteredApp)
runner.Step("OnSystemRequest_QueryApps_IsNotSentToTheSameAppInForeground",
  OnSystemRequest_QueryApps_IsNotSentToTheSameAppInForeground)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
