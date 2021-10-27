---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3717
---------------------------------------------------------------------------------------------------
-- Description: Check SDL ignores value of 'frameInfo' field for 'Single' and 'First' frames
-- Note: Scenario is applicable for encrypted and non-encrypted connection
--
-- Steps:
-- 1. App registered
-- 2. App sends PutFile data
--  a) as a single frame
--  b) as a multi frame
-- 3. Make sure App sends non-zero value in 'frameInfo' field of 'Single' and 'First' frames
-- SDL does:
--  - ignore value of 'frameInfo' field for 'Single' and 'First' frames
--  - proceed with PutFile successfully
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SSLHandshakeFlow/common")
local constants = require('protocol_handler/ford_protocol_constants')
local ph = require('protocol_handler/protocol_handler')
local utils = require("user_modules/utils")
local color = require("user_modules/consts").color

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
constants.FRAME_SIZE["P2"] = 1400
config.application2.registerAppInterfaceParams.appName = "server2"
config.application2.registerAppInterfaceParams.fullAppID = "spt2"

--[[ Local Variables ]]
local appParams = {
  [1] = { frames = "multi", protocolVersion = 2, cert = "./files/Security/spt_credential.pem" },
  [2] = { frames = "single", protocolVersion = 3, cert = "./files/Security/spt_credential_2.pem" }
}

local putFileParams = {
  syncFileName = "icon.png",
  fileType = "GRAPHIC_PNG",
  persistentFile = true,
  systemFile = false
}

--[[ Local Functions ]]
local function registerApp(pAppId)
  config.defaultProtocolVersion = appParams[pAppId].protocolVersion
  for _, v in pairs({"serverCertificatePath", "serverPrivateKeyPath", "serverCAChainCertPath" }) do
    config[v] = appParams[pAppId].cert
  end
  common.registerAppWOPTU(pAppId)
end

local function switchRPCServiceToProtected(pAppId)
  local serviceId = constants.SERVICE_TYPE.RPC
  common.getMobileSession(pAppId):ExpectHandshakeMessage()
  common.getMobileSession(pAppId):ExpectControlMessage(serviceId, {
    frameInfo = constants.FRAME_INFO.START_SERVICE_ACK,
    encryption = true
  })
  common.getMobileSession(pAppId):StartSecureService(serviceId)
end

local function updateProtocolHandler()
  local protocolHandler = ph.ProtocolHandler()
  local mt = getmetatable(protocolHandler)
  local GetBinaryFrame_Orig = mt.__index.GetBinaryFrame
  function mt.__index:GetBinaryFrame(msg)
    if msg.frameType == constants.FRAME_TYPE.SINGLE_FRAME then
      msg.frameInfo = 77 -- non-zero value
    end
    if msg.frameType == constants.FRAME_TYPE.FIRST_FRAME then
      msg.frameInfo = 78 -- non-zero value
    end
    utils.cprint(color.magenta, "frameType:", msg.frameType, "frameInfo:", msg.frameInfo)
    return GetBinaryFrame_Orig(self, msg)
  end
end

local function sendPutFileNonEncrypted(pAppId)
  local cid = common.getMobileSession(pAppId):SendRPC("PutFile", putFileParams, "files/action.png")
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendPutFileEncrypted(pAppId)
  local cid = common.getMobileSession(pAppId):SendEncryptedRPC("PutFile", putFileParams, "files/action.png")
  common.getMobileSession(pAppId):ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, init HMI", common.start)
runner.Step("Register App 1", registerApp, { 1 })
runner.Step("Register App 2", registerApp, { 2 })

runner.Title("Test")
runner.Step("Update ProtocolHandler", updateProtocolHandler)
for appId = 1, 2 do
  runner.Title("App ".. appId .. ", frames: " .. appParams[appId].frames)
  runner.Step("Send PutFile Non-encrypted", sendPutFileNonEncrypted, { appId })
  runner.Step("Start RPC Service protected", switchRPCServiceToProtected, { appId })
  runner.Step("Send PutFile Encrypted", sendPutFileEncrypted, { appId })
end

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
