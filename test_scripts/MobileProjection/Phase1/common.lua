---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local events = require("events")
local constants = require("protocol_handler/ford_protocol_constants")
local hmi_stream = require("modules/hmi_adapter/hmi_stream_adapter_controller")
local SDL = require('SDL')

--[[ Module ]]
local m = actions

m.wait = utils.wait
m.cloneTable = utils.cloneTable

--[[ @startService: start audio/video service
--! @parameters:
--! pService - service value
--! pAppId - app id value for session
--! @return: none
--]]
function m.startService(pService, pAppId)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StartService(pService)
  if pService == 10 then
    m.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end)
  elseif pService == 11 then
    m.getHMIConnection():ExpectRequest("Navigation.StartStream")
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end)
  else
    utils.cprint( 31, "Service for opening is not set")
  end
end

--[[ @StartStreaming: Start streaming
--! @parameters:
--! pService - service value
--! pFile -file for streaming
--! pAppId - app id value for session
--! @return: none
--]]
function m.StartStreaming(pService, pFile, pAppId)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StartStreaming(pService, pFile, 160*1024)
  if pService == 11 then
    m.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
  else
    m.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = true })
  end
  utils.cprint(33, "Streaming...")
  m.wait(1000)
end

--[[ @StopStreaming: Stop streaming
--! @parameters:
--! pService - service value
--! pFile -file for streaming
--! pAppId - app id value for session
--! @return: none
--]]
function m.StopStreaming(pService, pFile, pAppId)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StopStreaming(pFile)
  if pService == 11 then
    m.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false }):Timeout(15000)
  else
    m.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = false }):Timeout(15000)
  end
end

--[[ @ListenStreaming: Capture HMI bound streaming data to file
--! @parameters:
--! pService - service value
--! pBytesCount - how many bytes before the callback will be called
--! pFileToComparePath - file to compare received data to
--! @return: event which will be raised when stream data is received or times out
--]]
function m.ListenStreaming(pService, pBytesCount, pFileToComparePath)
  local function validateStreamingData(event, pFilePath)
    actions.hmi.getConnection():ExpectEvent(event, "Stream event")
    :ValidIf(function(_, data)
      if data.success then
        local recvFile = io.open(data.fileName, "rb")
        local recvData = recvFile:read(data.totalBytes)
        recvFile:close()

        local sentFile = io.open(pFilePath, "rb")
        local sentData = sentFile:read(data.totalBytes)
        sentFile:close()

        if sentData == recvData then
          return true
        else
          return false, "Streaming Data Received by HMI did not match the file sent"
        end
      end

      return false, "HMI received " .. tostring(data.totalBytes) .. " bytes of streaming data"
    end)
  end

  local consumer = "socket"
  if pService == 10 then
    consumer = actions.sdl.getSDLIniParameter("AudioStreamConsumer")
  elseif pService == 11 then
    consumer = actions.sdl.getSDLIniParameter("VideoStreamConsumer")
  end
  local isTcp = "socket" == consumer

  local event = actions.run.createEvent()
  event.service = pService
  event.matches = function(event1, event2)
    return event1.service == event2.service
  end

  if pFileToComparePath then
    validateStreamingData(event, pFileToComparePath)
  end

  local callback = function(pSuccess, pTotalBytes, pFileName)
    event.success = pSuccess
    event.totalBytes = pTotalBytes
    event.fileName = pFileName
    actions.hmi.getConnection():RaiseEvent(event, "Stream event")
  end

  if isTcp then
    local host = config.mobileHost
    local port
    if pService == 10 then
      port = actions.sdl.getSDLIniParameter("AudioStreamingPort")
    else
      port = actions.sdl.getSDLIniParameter("VideoStreamingPort")
    end

    hmi_stream.TcpConnection(host, port, pBytesCount, callback)
  else
    local pipe = SDL.AppStorage.path()
    if pService == 10 then
      pipe = pipe .. actions.sdl.getSDLIniParameter("NamedAudioPipePath")
    else
      pipe = pipe .. actions.sdl.getSDLIniParameter("NamedVideoPipePath")
    end
    hmi_stream.PipeConnection(pipe, pBytesCount, callback)
  end

  return event
end

--[[ @RejectingServiceStart: Rejecting audio/video service start
--! @parameters:
--! pService - service value
--! pAppId - app id value for session
--! @return: none
--]]
function m.RejectingServiceStart(pService, pAppId)
  if not pAppId then pAppId = 1 end
  local serviceType
  if 11 == pService then
    serviceType = constants.SERVICE_TYPE.VIDEO
  elseif 10 == pService then
    serviceType = constants.SERVICE_TYPE.PCM
  end
  local StartServiceResponseEvent = events.Event()
  StartServiceResponseEvent.matches =
  function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
      data.serviceType == serviceType and
      data.sessionId == m.getMobileSession(pAppId).sessionId and
      (data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK or
        data.frameInfo == constants.FRAME_INFO.START_SERVICE_ACK)
  end
  m.getMobileSession(pAppId):Send({
    frameType = constants.FRAME_TYPE.CONTROL_FRAME,
    serviceType = serviceType,
    frameInfo = constants.FRAME_INFO.START_SERVICE
  })
  -- Expect StartServiceNACK on mobile app from SDL, it means service is not started
  m.getMobileSession(pAppId):ExpectEvent(StartServiceResponseEvent, "Expect StartServiceNACK")
  :ValidIf(function(_, data)
      if data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK then
        return true
      else
        return false, "StartService ACK received"
      end
    end)
end

function m.StopService(pServiceId, pAppId)
  if not pAppId then pAppId = 1 end
  m.getMobileSession(pAppId):StopService(pServiceId)
end

return m
