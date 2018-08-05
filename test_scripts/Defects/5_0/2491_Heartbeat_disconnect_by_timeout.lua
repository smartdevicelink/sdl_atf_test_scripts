---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2491
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require('user_modules/utils')
local constants = require('protocol_handler/ford_protocol_constants')
local events = require('events')
local atf_logger = require('atf_logger')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 4

--[[ Local Functions ]]
local function ts_log(...)
  utils.cprint(35, "[" .. atf_logger.formated_time(true) .. "] " .. ...)
end

local function HBMsg(pId, pName)
  local event = events.Event()
  event.matches =
  function(_, data)
    return data.frameType == 0 and
    data.serviceType == 0 and
    data.sessionId == common.getMobileSession().sessionId and
    data.frameInfo == pId
  end
  local ret = common.getMobileSession():ExpectEvent(event, pName)
  ret:Do(function() ts_log("SDL->MOB: " .. pName) end)
  return ret
end

local function HBFromSDLMsg()
  return HBMsg(0, "HB")
end

local function HBACKFromSDLMsg()
  return HBMsg(255, "HB_ACK")
end

local function EndSrvcMsg()
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
    data.serviceType == 7 and data.frameInfo == constants.FRAME_INFO.END_SERVICE
  end
  local ret = common.getMobileSession():ExpectEvent(event, "EndService")
  ret:Do(function() ts_log("SDL->MOB: EndService RPC") end)
  return ret
end

local function openConnectionCreateSession()
  local session = common.getMobileSession()
  session.activateHeartbeat = false
  session.sendHeartbeatToSDL = false
  session.answerHeartbeatFromSDL = false
  session.ignoreSDLHeartBeatACK = false
  session:StartService(7)
  HBFromSDLMsg()
  :Times(0)
  utils.wait(10000)
end

local function RegisterAppInterface()
  local appParams = config.application1.registerAppInterfaceParams
  local cid = common.getMobileSession():SendRPC("RegisterAppInterface", appParams)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
    { application = { appName = appParams.appName }})
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  :Times(0)
  HBFromSDLMsg()
  :Times(0)
  utils.wait(5000)
end

local function sendHBFromMobileAndReceivingFromSDL()
  HBACKFromSDLMsg()
  common.getMobileSession():Send({
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      serviceType = constants.SERVICE_TYPE.CONTROL,
      frameInfo = constants.FRAME_INFO.HEARTBEAT
    })
  ts_log("MOB->SDL: HB")
end

local function disconnectDueToHeartbeat()
  local timeout = 16000
  HBFromSDLMsg()
  :Timeout(timeout)
  EndSrvcMsg()
  :Timeout(timeout)
  common.getMobileConnection():ExpectEvent(events.disconnectedEvent, "Disconnected")
  :Do(function() ts_log("Mobile disconnected") end)
  :Timeout(timeout)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Do(function() ts_log("SDL->HMI: BC.OnAppUnregistered") end)
  :Timeout(timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI", common.start)

runner.Title("Test")
runner.Step("OpenConnectionCreateSession", openConnectionCreateSession)
runner.Step("RegisterApp", RegisterAppInterface)
runner.Step("SendHBFromMobileAndReceivingFromSDL", sendHBFromMobileAndReceivingFromSDL)
runner.Step("DisconnectDueToHeartbeat", disconnectDueToHeartbeat)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
