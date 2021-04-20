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
-- 1. Mobile application sends file via PutFile chunks
-- 2. SDL process some part of chunks with success result code
-- 3. One chunk came with wrong crc value and SDL responds with result code "CORRUPTED_DATA" to mobile app
-- SDL does:
-- 1. After response "CORRUPTED_DATA" process all other chunks with resultCode "INVALID_DATA"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PutFile/commonPutFile')
local json = require("modules/json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local usedFile = "./files/icon.png"
local FramesCount = 10
local frameSize
local offsetValue = 0
local msgId = 1000
local correlationId = 1000
local binaryDataFrames

local corrDataResult = {
  success = false,
  resultCode = "CORRUPTED_DATA",
  info = "CRC Check on file failed. File upload has been cancelled, please retry."
}

local invalidDataResult = {
  success = false,
  resultCode = "INVALID_DATA",
}

local msg = {
  version = config.defaultProtocolVersion,
  encryption = false,
  frameType = 0x01,
  serviceType = 0x07,
  frameInfo = 0x0,
  rpcType = 0x0,
  rpcFunctionId = 32, -- PutFile
}

--[[ Local Functions ]]
local function prepareFileForsendingViaChunks()
  local f = assert(io.open(usedFile))
  local binaryData = f:read("*all")
  io.close(f)
  local binaryDataSize = #binaryData
  frameSize = binaryDataSize / FramesCount
  local frames = {}
  local stringOffset = 0
  for i = 1, FramesCount do
    frames[i] = string.sub(binaryData, stringOffset + 1, stringOffset + frameSize)
    stringOffset = i*frameSize
  end
  return frames
end

binaryDataFrames = prepareFileForsendingViaChunks()

local function getFrameCheckSum(pData)
  local file = "./files/tmp"
  local f = io.open(file, "w")
  f:write(pData)
  f:close()
  local crc = common.getCheckSum(file)
  os.remove(file)
  return crc
end

local function putFile(pParams, pBinaryData, pResult)
  msgId = msgId + 1
  correlationId = correlationId + 1

  msg.sessionId = common.getMobileSession().sessionId
  msg.messageId = msgId
  msg.rpcCorrelationId = correlationId
  msg.payload = json.encode(pParams)
  msg.binaryData = pBinaryData

  if not pResult then pResult = { success = true, resultCode = "SUCCESS" } end
  common.getMobileSession():Send(msg)
  common.getMobileSession():ExpectResponse(correlationId, pResult)
end

local function putFileSuccess()
  local params = common.putFileParams()
  for i = 1, 4 do
    params.crc = getFrameCheckSum(binaryDataFrames[i])
    params.offset = offsetValue
    putFile(params, binaryDataFrames[i])
    offsetValue = offsetValue + frameSize
  end
end

local function putFileCorruptedData()
  local params = common.putFileParams()
  params.crc = getFrameCheckSum(binaryDataFrames[5]) - 100
  params.offset = offsetValue
  putFile(params, binaryDataFrames[5], corrDataResult)
  offsetValue = offsetValue + frameSize
end

local function putFileInvalidData()
  local params = common.putFileParams()
  for i = 6, 10 do
    params.crc = getFrameCheckSum(binaryDataFrames[i])
    params.offset = offsetValue
    putFile(params, binaryDataFrames[i], invalidDataResult)
    offsetValue = offsetValue + frameSize
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration with iconResumed = false", common.registerApp)

runner.Title("Test")
runner.Step("Success PutFile with crc", putFileSuccess)
runner.Step("Corrupted data PutFile with crc", putFileCorruptedData)
runner.Step("Invalid data PutFile with crc", putFileInvalidData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
