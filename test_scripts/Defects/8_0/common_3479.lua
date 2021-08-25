---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local constants = require('protocol_handler/ford_protocol_constants')
local atf_logger = require("atf_logger")
local message_dispatcher = require("message_dispatcher")
local consts = require("user_modules/consts")

--[[ Module ]]
local m = {}

m.services = {
  audio = {
    id = 10,
    name = "AUDIO",
    rpc = "Navigation.StartAudioStream",
    rpc2 = "Navigation.StopAudioStream",
    notif = "Navigation.OnAudioDataStreaming",
    const = constants.SERVICE_TYPE.PCM,
    file = "files/MP3_1140kb.mp3",
    status = false
  },
  video = {
    id = 11,
    name = "VIDEO",
    rpc = "Navigation.StartStream",
    rpc2 = "Navigation.StopStream",
    notif = "Navigation.OnVideoDataStreaming",
    const = constants.SERVICE_TYPE.VIDEO,
    file = "files/MP3_4555kb.mp3",
    status = false
  }
}

m.ld = {
  [1] = "App->SDL",
  [2] = "SDL->HMI",
  [3] = "HMI->SDL",
  [4] = "SDL->App"
}

--[[ Proxy Functions ]]
m.start = actions.start
m.app = actions.app
m.hmi = actions.hmi
m.mobile = actions.mobile
m.sdl = actions.sdl
m.run = actions.run
m.wait = actions.run.wait
m.color = consts.color
m.constants = constants
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.runAfter = actions.run.runAfter

--[[ Common Functions ]]
function m.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter ..tostring(p)
  end
  utils.cprint(m.color.magenta, str)
end

local FileStream_Orig = message_dispatcher.FileStream
function message_dispatcher.FileStream(...)
  local stream = FileStream_Orig(...)
  local frameSize = (constants.FRAME_SIZE["P" .. stream.version] - constants.PROTOCOL_HEADER_SIZE)
  local chunkSize = (frameSize < stream.bandwidth) and frameSize or (stream.bandwidth)
  local numberOfChunksPerSecond = 4 -- allow to send 4 chunks per 1 second
  stream.chunksize = math.floor(chunkSize / numberOfChunksPerSecond + 0.5)
  local GetMessage_Orig = stream.GetMessage
  function stream:GetMessage(...)
    local msg = GetMessage_Orig(self, ...)
    return msg, 10
  end
  return stream
end

function m.sendEndService(pServiceType)
  m.getMobileSession():Send({
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      serviceType = pServiceType.const,
      frameInfo = constants.FRAME_INFO.END_SERVICE
    })
  m.log(m.ld[1], "EndService", pServiceType.name)
end

function m.sendEndServiceAck(pServiceType)
  m.getMobileSession():Send({
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      serviceType = pServiceType.const,
      frameInfo = constants.FRAME_INFO.END_SERVICE_ACK
    })
  m.log(m.ld[1], "EndServiceAck", pServiceType.name)
end

local createSession_Orig = actions.mobile.createSession
function actions.mobile.createSession(...)
  local session = createSession_Orig(...)
  function session:ExpectEndService(pServiceType)
    local event = actions.run.createEvent()
    event.matches = function(_, data)
      return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
        data.serviceType == pServiceType.id and
        data.sessionId == self.sessionId and
        data.frameInfo == constants.FRAME_INFO.END_SERVICE
    end
    local ret = session:ExpectEvent(event, "End Service Event")
    :Do(function() m.log(m.ld[4], "EndService", pServiceType.name) end)
    return ret
  end
  return session
end

function m.startStreaming(pServiceType, pStartStreamingDelay)
  if not pStartStreamingDelay then pStartStreamingDelay = 0 end
  local function f()
    m.getMobileSession():StartService(pServiceType.id)
    :Do(function() m.log(m.ld[1], "StartService", pServiceType.name) end)
    m.getHMIConnection():ExpectRequest(pServiceType.rpc)
    :Do(function(e, data)
        m.log(m.ld[2], data.method, e.occurences)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        m.log(m.ld[3], "SUCCESS:", data.method)
        m.getMobileSession():StartStreaming(pServiceType.id, pServiceType.file)
        m.getHMIConnection():ExpectNotification(pServiceType.notif, { available = true })
        :Do(function(_, data) m.log(m.ld[2], data.method, data.params.available) end)
        pServiceType.status = true
      end)
  end
  m.run.runAfter(f, pStartStreamingDelay)
end

function m.stopStreaming(pServiceType)
  if pServiceType.status then
    m.getMobileSession():StopStreaming(pServiceType.file)
    pServiceType.status = false
    m.log(m.ld[1], "Streaming stopped", pServiceType.name)
    m.sendEndService(pServiceType)
  end
end

function m.startStreamingNoAnswer(pServiceType, pStartStreamingDelay, pStopStreamingDelay, pSendEndServiceAck)
  if not pStartStreamingDelay then pStartStreamingDelay = 0 end
  if not pStopStreamingDelay then pStopStreamingDelay = 0 end
  if pSendEndServiceAck == nil then pSendEndServiceAck = true end
  local function f()
    m.getMobileSession():ExpectEndService(pServiceType)
    :Do(function()
        m.run.runAfter(function()
          m.stopStreaming(pServiceType)
          if pSendEndServiceAck then m.sendEndServiceAck(pServiceType) end
        end, pStopStreamingDelay)
     end)
    m.getMobileSession():StartService(pServiceType.id)
    :Do(function()
        m.log(m.ld[1], "StartService", pServiceType.name)
        m.getMobileSession():StartStreaming(pServiceType.id, pServiceType.file)
        m.log(m.ld[1], "Streaming started", pServiceType.name)
        m.getHMIConnection():ExpectNotification(pServiceType.notif,
          { available = true }, { available = false })
        :Do(function(_, data) m.log(m.ld[2], data.method, data.params.available) end)
        :Times(2)
        pServiceType.status = true
      end)
    m.getHMIConnection():ExpectRequest(pServiceType.rpc)
    :Do(function(e, data) m.log(m.ld[2], data.method, e.occurences) end)
    :Times(4)
  end
  local ret = m.getHMIConnection():ExpectRequest(pServiceType.rpc2)
  :Do(function(_, data)
      m.log(m.ld[2], data.method)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      m.log(m.ld[3], "SUCCESS:", data.method)
    end)
  m.run.runAfter(f, pStartStreamingDelay)
  return ret
end

return m
