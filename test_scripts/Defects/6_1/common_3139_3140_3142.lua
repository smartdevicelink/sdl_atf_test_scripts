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

m.streamFiles = {
  [1] = "files/SampleVideo_5mb.mp4",
  [2] = "files/MP3_4555kb.mp3"
}

m.streamingStatus = {
  [1] = nil,
  [2] = nil
}

m.tollerance = 500 --ms

m.ts = {}
m.seq = {
  hmi = {},
  app1 = {},
  app2 = {}
}
actions.minTimeout = 1000

--[[ Proxy Functions ]]
m.start = actions.start
m.activateApp = actions.activateApp
m.app = actions.app
m.hmi = actions.hmi
m.mobile = actions.mobile
m.sdl = actions.sdl
m.run = actions.run
m.wait = actions.run.wait
m.color = consts.color

--[[ Common Functions ]]
function m.print(...) utils.cprint(m.color.magenta, ...) end

function m.printTable(...) utils.cprintTable(m.color.magenta, ...) end

function m.timestamp(pEventName, pConType)
  m.ts[pEventName] = timestamp()

  local function isExist(pArray, pItem)
    for _, v in pairs(pArray) do
      if v == pItem then return true end
    end
    return false
  end

  local function insert(pTable, pItem)
    if not isExist(pTable, pItem) then table.insert(pTable, pItem) end
  end
  if pConType then
    insert(m.seq[pConType], pEventName)
  else
    for k in pairs(m.seq) do
      insert(m.seq[k], pEventName)
    end
  end
end

function m.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(m.color.magenta, str)
end

function m.preconditions(pParamValues)
  actions.preconditions()
  if pParamValues and type(pParamValues) == "table" then
    for p, v in pairs(pParamValues) do
      utils.cprint(m.color.magenta, p, v)
      m.sdl.setSDLIniParameter(p, v)
    end
  end
end

function m.postconditions()
  for appId, v in pairs(m.streamingStatus) do
    if v == true then
      m.stopStreaming(appId)
    end
  end
  actions.postconditions()
end

function m.startStreaming(pAppId, pServiceId)
  local notName
  local reqName
  if pServiceId == 10 then
    notName = "Navigation.OnAudioDataStreaming"
    reqName = "Navigation.StartAudioStream"
  elseif pServiceId == 11 then
    notName = "Navigation.OnVideoDataStreaming"
    reqName = "Navigation.StartStream"
  end
  m.mobile.getSession(pAppId):StartService(pServiceId)
  :Do(function()
      m.mobile.getSession(pAppId):StartStreaming(pServiceId, m.streamFiles[pAppId], 10000)
      m.hmi.getConnection():ExpectNotification(notName, { available = true })
      m.log("App " .. pAppId .." starts streaming ...")
      m.streamingStatus[pAppId] = true
    end)
  m.hmi.getConnection():ExpectRequest(reqName, { appID = m.app.getHMIId(pAppId) })
  :Do(function(_, data)
      m.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

function m.stopStreaming(pAppId)
  if m.streamingStatus[pAppId] == true then
    m.mobile.getSession(pAppId):StopStreaming(m.streamFiles[pAppId])
    m.log("App " .. pAppId .. " stops streaming")
    m.streamingStatus[pAppId] = false
  else
    utils.cprint(m.color.yellow, "Streaming is unable to stop since it's not started")
  end
end

function m.registerApp(pAppId)
  if not pAppId then pAppId = 1 end
  local session = m.mobile.createSession(pAppId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", m.app.getParams(pAppId))
      m.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      :Do(function(_, d)
          m.app.setHMIId(d.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      function session:ExpectEndService(pServiceId)
        local event = m.run.createEvent()
        event.matches = function(_, data)
          return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
            data.serviceType == pServiceId and
            data.sessionId == self.sessionId and
            data.frameInfo == constants.FRAME_INFO.END_SERVICE
        end
        return session:ExpectEvent(event, "End Service Event")
      end
      function session:SendEndServiceAck(pServiceId)
        self:Send({
          frameType = constants.FRAME_TYPE.CONTROL_FRAME,
          serviceType = pServiceId,
          frameInfo = constants.FRAME_INFO.END_SERVICE_ACK
        })
      end
    end)
  return session:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" })
end

function m.checkTimeout(pBaseParam, pVerifiedParam, pExpTS, pTollerance)
  if not pTollerance then pTollerance = m.tollerance end
  if m.ts[pBaseParam] then
    if m.ts[pVerifiedParam] == nil then
      m.run.fail(pVerifiedParam .. " is not received")
    else
      local delay = math.abs(m.ts[pVerifiedParam] - m.ts[pBaseParam])
      if delay > pExpTS + pTollerance then
        m.run.fail("Delay between `" .. pBaseParam .. "` and `" .. pVerifiedParam .. "` is too high, expected ~ "
          .. pExpTS .. "ms(+" .. pTollerance .. "), actual " .. delay .. "ms")
      end
      if delay < pExpTS - pTollerance then
        m.run.fail("Delay between `" .. pBaseParam .. "` and `" .. pVerifiedParam .. "` is too low, expected ~ "
          .. pExpTS .. "ms(-" .. pTollerance .. "), actual " .. delay .. "ms")
      end
    end
  end
end

function m.checkSequence(pConType, pExpSeq)
  local function arraysEqual(pTbl1, pTbl2)
    if #pTbl1 ~= #pTbl2 then return false end
    for k in pairs(pTbl1) do
      if pTbl1[k] ~= pTbl2[k] then return false end
    end
    return true
  end
  local seq = m.seq[pConType]
  if not arraysEqual(pExpSeq, seq) then
    m.run.fail("Expected sequence:\n" .. utils.tableToString(pExpSeq) .. "\nActual:\n" .. utils.tableToString(seq))
  end
end

function m.deactivateApp(pAppId)
  m.hmi.getConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = m.app.getHMIId(pAppId) })
  m.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", videoStreamingState = "STREAMABLE" })
end

local FileStream_Orig = message_dispatcher.FileStream
function message_dispatcher.FileStream(...)
  local stream = FileStream_Orig(...)
  local frameSize = (constants.FRAME_SIZE["P" .. stream.version] - constants.PROTOCOL_HEADER_SIZE)
  local chunkSize = (frameSize < stream.bandwidth) and frameSize or (stream.bandwidth)
  local numberOfChunksPerSecond = 10 -- allow to send 10 chunks per 1 second
  stream.chunksize = math.floor(chunkSize / numberOfChunksPerSecond + 0.5)
  local GetMessage_Orig = stream.GetMessage
  function stream:GetMessage(...)
    local msg = GetMessage_Orig(self, ...)
    return msg, 10
  end
  return stream
end

return m
