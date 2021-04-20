----------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3659
----------------------------------------------------------------------------------------------------
-- Description: Check SDL does not encrypt payload in first frame of multi-frame message
--
-- Steps:
-- 1. New app is registered and established secure connection for RPC service
-- 2. HMI sends BS.OnSystemRequest with binary data (size > 16384 bytes)
-- SDL does:
--  - Transfer notification to mobile
--  - Payload of first frame is not encrypted
--  - Payload of consecutive frames is encrypted
----------------------------------------------------------------------------------------------------
--[[ Local Variables ]]
local encryptionFlagFirstFrame = nil
local encryptionFlagConsecutiveFrames = {}

--[[ Override ATF functions ]]
local function overrideOnInputData()
  local mobile = require("mobile_connection")
  local ph = require('protocol_handler/protocol_handler')
  local constants = require('protocol_handler/ford_protocol_constants')
  local atf_logger = require("atf_logger")
  function mobile.mt.__index:OnInputData(messageHandlerFunc)
    local protocol_handler = ph.ProtocolHandler()
    local frameHandlerFunc =
      function(frameMessage)
        frameMessage._technical.isFrame = true
        messageHandlerFunc(self, frameMessage)
        frameMessage._technical.isFrame = false
      end
    local f =
    function(_, binary)
      local function bytesToInt32(val, offset)
        local res = bit32.lshift(string.byte(val, offset), 24) +
        bit32.lshift(string.byte(val, offset + 1), 16) +
        bit32.lshift(string.byte(val, offset + 2), 8) +
        string.byte(val, offset + 3)
        return res
      end
      local function parseProtocolHeader(buffer)
          local size = bytesToInt32(buffer, 5)
          if #buffer < size + constants.PROTOCOL_HEADER_SIZE then
            return nil
          end
          local msg = {}
          local firstByte = string.byte(buffer, 1)
          msg.frameType = bit32.band(firstByte, 0x07)
          msg.encryption = bit32.band(firstByte, 0x08) == 0x08
          msg.serviceType = string.byte(buffer, 2)
          msg.size = size
          return msg
      end
      local function parseFrames(framesData)
        local buffer = framesData
        while #buffer >= constants.PROTOCOL_HEADER_SIZE do
          local msg = parseProtocolHeader(buffer)
          if not msg then break end
          buffer = string.sub(buffer, msg.size + constants.PROTOCOL_HEADER_SIZE + 1)
          if msg.serviceType == constants.SERVICE_TYPE.BULK_DATA then
            print("Parse:", msg.serviceType, msg.frameType, msg.encryption)
            if msg.frameType == 2 then encryptionFlagFirstFrame = msg.encryption end
            if msg.frameType == 3 then table.insert(encryptionFlagConsecutiveFrames, msg.encryption) end
          end
        end
      end
      parseFrames(binary)
      local msgs = protocol_handler:Parse(binary, nil, frameHandlerFunc)
      for _, msg in ipairs(msgs) do
        atf_logger.LOG("SDLtoMOB", msg)
        messageHandlerFunc(self, msg)
      end
    end
    self.connection:OnInputData(f)
  end
end

overrideOnInputData()

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SSLHandshakeFlow/common")
local constants = require('protocol_handler/ford_protocol_constants')

--[[ Test Restrictions ]]
runner.isTestApplicable({ { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } })

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.checkAllValidations = true
config.defaultProtocolVersion = 3
constants.FRAME_SIZE["P3"] = 16384

--[[ Local Functions ]]

local function startServiceProtectedACK()
  local serviceId = 7
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
  common.getMobileSession():ExpectHandshakeMessage()
end

local function startPTU()
  local cid = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoints" })
  common.getHMIConnection():ExpectResponse(cid)
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = common.sdl.getPTSFilePath() })
      common.getMobileSession():ExpectEncryptedNotification("OnSystemRequest")
      :ValidIf(function()
          if encryptionFlagFirstFrame == nil then
            return false, "First frame hasn't received"
          elseif encryptionFlagFirstFrame == true then
            return false, "First frame is encrypted"
          end
          return true, "First frame is not encrypted"
        end)
      :ValidIf(function()
          if #encryptionFlagConsecutiveFrames == 0 then
            return false, "Consecutive frames haven't received"
          end
          for id, encryptionFlag in pairs(encryptionFlagConsecutiveFrames) do
            if encryptionFlag == false then
              return false, "Consecutive frame " .. id .. " is not encrypted"
            end
          end
          return true, "All consecutive frames are encrypted"
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Switch RPC Service to Protected mode ACK", startServiceProtectedACK)

runner.Step("PTU, HMI sends BC.OnSystemRequest", startPTU)

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
