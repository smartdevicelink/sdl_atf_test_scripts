---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0037-Expand-Mobile-putfile-RPC.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- Mobile application sends a PutFile with correct checksum
-- And some bytes of the data were corrupted
-- SDL does:
-- Receive PutFile, verify counted checksum and respond with result code "CORRUPTED_DATA"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PutFile/commonPutFile')
local utils = require("user_modules/utils")
local json = require("modules/json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local fileName = "./files/action.png"

local PROTOCOL_HEADER_SIZE = 12

local function getProtocolFrameSize(pVersion)
  if pVersion == 2 then
    return 1500
  else
    return 131084
  end
end

local function int32ToBytes(pVal)
  local res = string.char(
    bit32.rshift(bit32.band(pVal, 0xff000000), 24),
    bit32.rshift(bit32.band(pVal, 0xff0000), 16),
    bit32.rshift(bit32.band(pVal, 0xff00), 8),
    bit32.band(pVal, 0xff)
  )
  return res
end

local function createProtocolHeader(pMessage)
  local res = string.char(
    bit32.bor(
      bit32.lshift(pMessage.version, 4),
      (pMessage.encryption and 0x08 or 0),
      bit32.band(pMessage.frameType, 0x07)),
    pMessage.serviceType,
    pMessage.frameInfo,
    pMessage.sessionId) ..
  (pMessage.binaryData and int32ToBytes(#pMessage.binaryData) or string.char(0, 0, 0, 0)) ..
  int32ToBytes(pMessage.messageId)
  return res
end

local function GetBinaryFrame(pMessage)
  local max_protocol_payload_size = getProtocolFrameSize(pMessage.version)
     - PROTOCOL_HEADER_SIZE
  if pMessage.binaryData then
    if #pMessage.binaryData > max_protocol_payload_size then
      error("Size of current frame is bigger than max frame size for protocol version " .. pMessage.version)
    end
  else
    pMessage.binaryData = ""
  end
  return createProtocolHeader(pMessage) .. pMessage.binaryData
end

local function SendFrame(pFrameMessage)
  local frame = GetBinaryFrame(pFrameMessage)
  local mobileConnection = common.getMobileSession().mobile_session_impl.connection
  mobileConnection.connection:Send({frame})
end

local function rpcPayload(pMsg)
  pMsg.payload = pMsg.payload or ""
  pMsg.binaryData = pMsg.binaryData or ""
  local res = string.char(
    bit32.lshift(pMsg.rpcType, 4) + bit32.band(bit32.rshift(pMsg.rpcFunctionId, 24), 0x0f),
    bit32.rshift(bit32.band(pMsg.rpcFunctionId, 0xff0000), 16),
    bit32.rshift(bit32.band(pMsg.rpcFunctionId, 0xff00), 8),
    bit32.band(pMsg.rpcFunctionId, 0xff)) ..
  int32ToBytes(pMsg.rpcCorrelationId) ..
  int32ToBytes(#pMsg.payload) ..
  pMsg.payload .. pMsg.binaryData
  return res
end

local function putFileByFrames(pParams)
  local putFileParams = {
    syncFileName = "action.png",
    fileType = "GRAPHIC_PNG",
    crc = common.getCheckSum(fileName)
  }

  local correlationId = common.getMobileSession().correlationId + 1

  local msg = {
    version = config.defaultProtocolVersion,
    encryption = false,
    frameType = 0x01,
    serviceType = 0x07,
    frameInfo = 0x0,
    sessionId = common.getMobileSession().sessionId,
    messageId = 1000,
    rpcType = 0x0,
    rpcFunctionId = 32, -- PutFile
    rpcCorrelationId = correlationId,
    payload = json.encode(putFileParams)
  }

  local file = fileName

  local f = assert(io.open(file))
  msg.binaryData = f:read("*all")
  io.close(f)

  msg.binaryData = rpcPayload(msg)

  local frames = {}
  local binaryDataSize = #msg.binaryData
  local max_size = 1400
  local frameMessage = {
    version = msg.version,
    encryption = msg.encryption,
    serviceType = msg.serviceType,
    sessionId = msg.sessionId,
    messageId = msg.messageId
  }
  if binaryDataSize > max_size then
    local countOfDataFrames = 0
    -- Create messages consecutive frames
    while #msg.binaryData > 0 do
      countOfDataFrames = countOfDataFrames + 1

      local dataPart = string.sub(msg.binaryData, 1, max_size)
      msg.binaryData = string.sub(msg.binaryData, max_size + 1)

      local frame_info = 0 -- last frame
      if #msg.binaryData > 0 then
        frame_info = ((countOfDataFrames - 1) % 255) + 1
      end

      local consecutiveFrameMessage = utils.cloneTable(frameMessage)
      consecutiveFrameMessage.frameType = 0x03
      consecutiveFrameMessage.frameInfo = frame_info
      consecutiveFrameMessage.binaryData = dataPart
      table.insert(frames, consecutiveFrameMessage)
    end

    -- Create message firstframe
    local firstFrameMessage = utils.cloneTable(frameMessage)
    firstFrameMessage.frameType = 0x02
    firstFrameMessage.frameInfo = 0
    firstFrameMessage.binaryData = int32ToBytes(binaryDataSize) .. int32ToBytes(countOfDataFrames)
    firstFrameMessage.encryption = false
    table.insert(frames, 1, firstFrameMessage)
  else
    table.insert(frames, msg)
  end

  common.getMobileSession().mobile_session_impl.rpc_services:CheckCorrelationID(msg)

  local function replaceChar(pStr, pPos, pChar)
    return string.sub(pStr, 1, pPos - 1) .. pChar .. string.sub(pStr, pPos + 1, string.len(pStr))
  end

  if pParams.isDataCorrupted == true then
    frames[3].binaryData = replaceChar(frames[3].binaryData, 12, 'z')
  end

  for _, frame in pairs(frames) do
    SendFrame(frame)
  end

  common.getMobileSession():ExpectResponse(correlationId,
    { success = pParams.success, resultCode = pParams.resultCode })

end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration with iconResumed = false", common.registerApp)

runner.Title("Test")
runner.Step("Upload file as multiple frames SUCCESS", putFileByFrames, {
  { isDataCorrupted = false, success = true, resultCode = "SUCCESS" }
})
runner.Step("Upload file as multiple frames CORRUPTED_DATA", putFileByFrames, {
  { isDataCorrupted = true, success = false, resultCode = "CORRUPTED_DATA" }
})
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
