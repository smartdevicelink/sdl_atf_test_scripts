local common = require('test_scripts/Smoke/commonSmoke')

local commonSubtleAlert = common

function commonSubtleAlert.sendOnSystemContext(pCtx, appID)
  common.getHMIConnection():SendNotification("UI.OnSystemContext", {
    appID = common.getHMIAppId(appID),
    systemContext = pCtx
  })
end

function commonSubtleAlert.subtleAlert(pParams, prepareFunc, interruptTTS)
  local params = prepareFunc(pParams)

  local cid = common.getMobileSession():SendRPC("SubtleAlert", params.requestParams)
  local subtleAlertActive = true;
  local ttsSpeakActive = params.requestParams.ttsChunks ~= nil;

  common.getHMIConnection():ExpectRequest("UI.SubtleAlert", params.uiRequestParams)
  :ValidIf(function(_, data)
      -- Verify that duration is omitted when softbuttons are sent
      return params.uiRequestParams.softbuttons == nil or data.params.duration == nil
    end)
  :Do(function(_, data)
      commonSubtleAlert.sendOnSystemContext("ALERT")
      local function alertResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        subtleAlertActive = false
        if not ttsSpeakActive then
          commonSubtleAlert.sendOnSystemContext("MAIN")
        end
      end
      common.runAfter(alertResponse, 3000)
    end)

  if params.requestParams.ttsChunks ~= nil then
    params.ttsSpeakRequestParams.appID = common.getHMIAppId()
    common.getHMIConnection():ExpectRequest("TTS.Speak", params.ttsSpeakRequestParams)
    :Do(function(_, data)
        local speakID = data.id
        common.getHMIConnection():SendNotification("TTS.Started")
        local function speakResponse(result)
          if result == nil then result = "SUCCESS" end
          common.getHMIConnection():SendResponse(data.id, "TTS.Speak", result, { })
          common.getHMIConnection():SendNotification("TTS.Stopped")
          ttsSpeakActive = false
          if not subtleAlertActive then
            commonSubtleAlert.sendOnSystemContext("MAIN")
          end
        end
        if interruptTTS then
          common.getHMIConnection():ExpectRequest("TTS.StopSpeaking")
          :Do(function(_, data)
              common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
              speakResponse("ABORTED")
            end)
        else
          common.runAfter(speakResponse, 2000)
        end
      end)
    :ValidIf(function(_, data)
        if #data.params.ttsChunks == 1 then
          return true
        else
          return false, "ttsChunks array in TTS.Speak request has wrong element number."
            .. " Expected 1, actual " .. tostring(#data.params.ttsChunks)
        end
      end)

    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
      { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(4)
  else
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(2)
  end

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function commonSubtleAlert.subtleAlertAbortedByVR(pParams, prepareFunc)
  local params = prepareFunc(pParams)

  local cid = common.getMobileSession():SendRPC("SubtleAlert", params.requestParams)

  common.getHMIConnection():ExpectRequest("UI.SubtleAlert", params.uiRequestParams)
  :ValidIf(function(_, data)
      -- Verify that duration is omitted when softbuttons are sent
      return params.uiRequestParams.softbuttons == nil or data.params.duration == nil
    end)
  :Do(function(_, data)
      commonSubtleAlert.sendOnSystemContext("ALERT")
      local function alertResponse()
        common.getHMIConnection():SendNotification("VR.Started")
        commonSubtleAlert.sendOnSystemContext("VRSESSION")

        common.getHMIConnection():SendResponse(data.id, data.method, "ABORTED", { })
      end
      common.runAfter(alertResponse, 3000)
    end)

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
    { systemContext = "VRSESSION", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" })
  :Times(3)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "ABORTED" })
end

function commonSubtleAlert.subtleAlertRejectedPhoneCall(pParams, prepareFunc)
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", 
    { eventName = "PHONE_CALL", isActive = true })

  local params = prepareFunc(pParams)

  local cid = common.getMobileSession():SendRPC("SubtleAlert", params.requestParams)
  common.getHMIConnection():ExpectRequest("UI.SubtleAlert", params.uiRequestParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "REJECTED", { })
    end)

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)

  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "REJECTED" })

  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", 
    { eventName = "PHONE_CALL", isActive = false })
end

return commonSubtleAlert