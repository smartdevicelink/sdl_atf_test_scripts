---------------------------------------------------------------------------------------------------
-- Navigation common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.appID = "SPT"
-- config.cipherListString = ":SSLv2:AES256-GCM-SHA384"

--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/4_5/Trigger_PTU_NO_Certificate/common')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local json = require("modules/json")
local constants = require('protocol_handler/ford_protocol_constants')
constants.FRAME_SIZE["P9"] = 131084 -- add unsupported SDL protocol version

local m = {}

--[[ Constants ]]
local fileName = "files/action.png"

--[[ Variables ]]
local originalValuesInSDL = {}
local msgId = 1000

--[[ Functions ]]

--[[ @ptUpdate: add certificate to policy table
--! @parameters:
--! pTbl - policy table to update
--! @return: none
--]]
function m.ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential.pem"
  local crt = common.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
end

--[[ @setSDLConfigParameter: change original value of parameter in SDL .ini file
--! @parameters:
--! pParamName - name of the parameter
--! pParamValue - value to be set
--! @return: none
--]]
function m.setSDLConfigParameter(pParamName, pParamValue)
  originalValuesInSDL[pParamName] = commonFunctions:read_parameter_from_smart_device_link_ini(pParamName)
  commonFunctions:write_parameter_to_smart_device_link_ini(pParamName, pParamValue)
end

--[[ @restoreSDLConfigParameters: restore original values of parameters in SDL .ini file
--! @parameters: none
--! @return: none
--]]
local function restoreSDLConfigParameters()
  for pParamName, pParamValue in pairs(originalValuesInSDL) do
    commonFunctions:write_parameter_to_smart_device_link_ini(pParamName, pParamValue)
  end
end

--[[ @postconditions: postcondition steps
--! @parameters: none
--! @return: none
--]]
function m.postconditions()
  StopSDL()
  restoreSDLConfigParameters()
end

--[[ @bytesToInt32: convert bytes to int32
--! @parameters:
--! val - value to convert
--! offset - offset
--! @return: value in int32
--]]
local function bytesToInt32(pVal, pOffset)
  local res = bit32.lshift(string.byte(pVal, pOffset), 24) +
  bit32.lshift(string.byte(pVal, pOffset + 1), 16) +
  bit32.lshift(string.byte(pVal, pOffset + 2), 8) +
  string.byte(pVal, pOffset + 3)
  return res
end

--[[ @int32ToBytes: convert int32 to bytes
--! @parameters:
--! val - value to convert
--! @return: value in bytes
--]]
local function int32ToBytes(pVal)
  local res = string.char(
    bit32.rshift(bit32.band(pVal, 0xff000000), 24),
    bit32.rshift(bit32.band(pVal, 0xff0000), 16),
    bit32.rshift(bit32.band(pVal, 0xff00), 8),
    bit32.band(pVal, 0xff)
  )
  return res
end

--[[ @rpcPayload: create payload for RPC
--! @parameters:
--! msg - message table to populate
--! @return: populated message
--]]
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

--[[ @putFileByFrames: process PutFile RPC frame by frame
--! @parameters:
--! pParams - table with parameters (file, isSentDataEncrypted, isUnexpectedFrameInserted, isMalformedFrameInserted)
--]]
function m.putFileByFrames(pParams)
  msgId = msgId + 1

  local putFileParams = {
    syncFileName = "action_" .. msgId .. " .png",
    fileType = "GRAPHIC_PNG",
    persistentFile = true,
    systemFile = false,
  }

  local correlationId = common.getMobileSession().correlationId + 1

  local msg = {
    version = config.defaultProtocolVersion,
    encryption = pParams.isSentDataEncrypted,
    frameType = 0x01,
    serviceType = 0x07,
    frameInfo = 0x0,
    sessionId = common.getMobileSession().sessionId,
    messageId = msgId,
    rpcType = 0x0,
    rpcFunctionId = 32, -- PutFile
    rpcCorrelationId = correlationId,
    payload = json.encode(putFileParams)
  }

  local file = fileName
  if pParams.file then file = pParams.file end

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

      local consecutiveFrameMessage = commonFunctions:cloneTable(frameMessage)
      consecutiveFrameMessage.frameType = 0x03
      consecutiveFrameMessage.frameInfo = frame_info
      consecutiveFrameMessage.binaryData = dataPart
      table.insert(frames, consecutiveFrameMessage)
    end

    -- Create message firstframe
    local firstFrameMessage = commonFunctions:cloneTable(frameMessage)
    firstFrameMessage.frameType = 0x02
    firstFrameMessage.frameInfo = 0
    firstFrameMessage.binaryData = int32ToBytes(binaryDataSize) .. int32ToBytes(countOfDataFrames)
    if pParams.isFirstFrameEncrypted ~= nil then
      firstFrameMessage.encryption = pParams.isFirstFrameEncrypted
    end
    table.insert(frames, 1, firstFrameMessage)
  else
    table.insert(frames, msg)
  end

  common.getMobileSession().mobile_session_impl.rpc_services:CheckCorrelationID(msg)

  if pParams.isUnexpectedFrameInserted == true then
    frames[4] = frames[3]
    frames[3] = commonFunctions:cloneTable(frames[2])
    frames[3].binaryData = '123'
  end

  if pParams.isMalformedFrameInserted == true then
    frames[4] = frames[3]
    frames[3] = commonFunctions:cloneTable(frames[2])
    frames[2].version = 9 -- incorrect protocol version
  end

  for _, frame in pairs(frames) do
    common.getMobileSession():SendPacket(frame)
  end

  if pParams.isSessionEncrypted == false then
    common.getMobileSession():ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
  else
    common.getMobileSession():ExpectEncryptedResponse(correlationId, { success = true, resultCode = "SUCCESS"})
  end

  common.getMobileSession():ExpectPacket({
      sessionId = common.getMobileSession().sessionId,
      frameType = 0x01,
      serviceType = 0x07
    },
    function(binaryData)
      local rpcFunctionId = bit32.band(bytesToInt32(binaryData, 1), 0x0fffffff)
      local rpcCorrelationId = bytesToInt32(binaryData, 5)
      if rpcFunctionId ~= 32 or rpcCorrelationId ~= correlationId then return false end
      return true
    end)
end

--[[ @startServiceProtected: start (or switch) service in protected mode
--! @parameters:
--! pServiceId - service id
--! @return: none
--]]
function m.startServiceProtected(pServiceId)
  common.getMobileSession():StartSecureService(pServiceId)
  common.getMobileSession():ExpectHandshakeMessage()
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
end

--[[ @protect: make table immutable
--! @parameters:
--! pTbl - mutable table
--! @return: immutable table
--]]
local function protect(pTbl)
  local mt = {
    __index = pTbl,
    __newindex = function(_, k, v)
      error("Attempting to change item " .. tostring(k) .. " to " .. tostring(v), 2)
    end
  }
  return setmetatable({}, mt)
end

-- Proxies for the inherited functions
local inheritedFunctions = {
  "getMobileSession", "getHMIConnection", "preconditions", "start", "registerApp", "policyTableUpdate", "activateApp"
}
for _, v in pairs(inheritedFunctions) do
  m[v] = function(...)
    return common[v](...)
  end
end

return protect(m)
