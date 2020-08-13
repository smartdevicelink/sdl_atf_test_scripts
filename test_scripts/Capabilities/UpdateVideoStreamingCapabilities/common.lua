---------------------------------------------------------------------------------------------------
-- Common module for VideoStreamingCapability
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local hmi_values = require('user_modules/hmi_values')
local SDL = require('SDL')
local events = require('events')
local utils = require("user_modules/utils")
local constants = require('protocol_handler/ford_protocol_constants')
local bson = require("bson4lua")
local security = require("user_modules/sequences/security")
local test = require("user_modules/dummy_connecttest")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5
config.ValidateSchema = false
constants.FRAME_SIZE.P5 = 131084

--[[ Shared Functions ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.postconditions = actions.postconditions
m.preconditions = actions.preconditions
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.getHMIAppId = actions.app.getHMIId
m.getHMIConnection = actions.hmi.getConnection
m.getMobileSession = actions.mobile.getSession
m.setSDLIniParameter = actions.sdl.setSDLIniParameter
m.cloneTable = utils.cloneTable
m.toString = utils.toString
m.isTableEqual = utils.isTableEqual
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.spairs = utils.spairs
m.policyTableUpdate = actions.policyTableUpdate
m.registerApp = actions.registerApp

--[[ Common Variables ]]
local hmiDefaultCapabilities = hmi_values.getDefaultHMITable()

local bsonType = {
  DOUBLE   = 0x01,
  STRING   = 0x02,
  DOCUMENT = 0x03,
  ARRAY    = 0x04,
  BOOLEAN  = 0x08,
  INT32    = 0x10,
  INT64    = 0x12
}

--[[ Overridden Functions ]]
local initHMI_onReady_Orig = test.initHMI_onReady
function test:initHMI_onReady(hmi_table)
  return initHMI_onReady_Orig(self, hmi_table, false)
end

--[[ Common Functions ]]
local function getSystemTimeValue()
  local dd = os.date("*t")
  return {
    millisecond = 0,
    second = dd.sec,
    minute = dd.min,
    hour = dd.hour,
    day = dd.day,
    month = dd.month,
    year = dd.year,
    tz_hour = 2,
    tz_minute = 0
  }
end

local function registerGetSystemTimeResponse()
  actions.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemTime")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { systemTime = getSystemTimeValue() })
    end)
  :Pin()
  :Times(AnyNumber())
end

function m.startWithGetSystemTime(pHMIParams)
  local event = actions.run.createEvent()
  actions.init.SDL()
  :Do(function()
      actions.init.HMI()
      :Do(function()
        actions.init.HMI_onReady(pHMIParams or hmiDefaultCapabilities)
          :Do(function()
              actions.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
              registerGetSystemTimeResponse()
              actions.init.connectMobile()
              :Do(function()
                  actions.init.allowSDL()
                  :Do(function()
                      actions.hmi.getConnection():RaiseEvent(event, "Start event")
                    end)
                end)
            end)
        end)
    end)
  return actions.hmi.getConnection():ExpectEvent(event, "Start event")
end

function m.start(pHMIParams)
  return actions.start(pHMIParams or hmiDefaultCapabilities)
end

function m.getVscData(pIdx)
  pIdx = pIdx or 1
  local videoStreamingCapabilitiesWithOutAddVSC = {
    [1] = {
      preferredResolution = {
        resolutionWidth = 5000,
        resolutionHeight = 5000
      },
      maxBitrate = 1073741823,
      supportedFormats = {{
        protocol = "RTP",
        codec = "VP9"
      }},
      hapticSpatialDataSupported = true,
      diagonalScreenSize = 1000,
      pixelPerInch = 500,
      scale = 5.5
    },
    [2] = {
      preferredResolution = {
        resolutionWidth = 200,
        resolutionHeight = 200
      },
      maxBitrate = 200,
      supportedFormats = {{
        protocol = "WEBM",
        codec = "H265"
      }},
      hapticSpatialDataSupported = false,
      diagonalScreenSize = 200,
      pixelPerInch = 200,
      scale = 3
    }
  }
  return utils.cloneTable(videoStreamingCapabilitiesWithOutAddVSC[pIdx])
end

function m.getVscFromDefaultCapabilitiesFile()
  return SDL.HMICap.get().UI.systemCapabilities.videoStreamingCapability
end

function m.buildVideoStreamingCapabilities(pArraySizeAddVSC)
  if not pArraySizeAddVSC then pArraySizeAddVSC = 1 end
  local vSC = m.getVscData()
  vSC.additionalVideoStreamingCapabilities = {}
  if pArraySizeAddVSC == 0 then
    vSC.additionalVideoStreamingCapabilities = m.getVscData(2)
  else
    for i = 1, pArraySizeAddVSC do
      vSC.additionalVideoStreamingCapabilities[i] = m.getVscData(2)
    end
  end
  return vSC
end

function m.setVideoStreamingCapabilities(pVSC)
  if not pVSC then pVSC = m.buildVideoStreamingCapabilities() end
  hmiDefaultCapabilities.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability = pVSC
end

function m.getSystemCapability(pSubscribe, pAppId, pResponseParams)
  if not pAppId then pAppId = 1 end
  if not pResponseParams then pResponseParams = m.buildVideoStreamingCapabilities() end
  local requestParams = {
    systemCapabilityType = "VIDEO_STREAMING",
    subscribe = pSubscribe
  }
  local corId = actions.getMobileSession(pAppId):SendRPC("GetSystemCapability", requestParams)
  actions.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS",
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING"
    }
  })
  :ValidIf(function(_, data)
    if not m.isTableEqual(pResponseParams, data.payload.systemCapability.videoStreamingCapability) then
      return false, "Parameters of the response are incorrect: \nExpected: " .. m.toString(pResponseParams)
      .. "\nActual: " .. m.toString(data.payload)
    end
    return true
  end)
end

function m.getSystemCapabilityExtended(pAppId, pVsc)
  pAppId = pAppId or 1
  pVsc = pVsc or m.buildVideoStreamingCapabilities()
  local requestParams = {
    systemCapabilityType = "VIDEO_STREAMING"
  }
  local responseParams = {
    success = true,
    resultCode = "SUCCESS",
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = pVsc
    }
  }
  local corId = m.getMobileSession(pAppId):SendRPC("GetSystemCapability", requestParams)
  m.getHMIConnection():ExpectRequest("UI.GetCapabilities"):Times(0)
  m.getMobileSession(pAppId):ExpectResponse(corId, responseParams)
  :ValidIf(function(_, data)
    if not m.isTableEqual(responseParams, data.payload) then
      return false, "Parameters of the response are incorrect: \nExpected: " .. m.toString(responseParams)
      .. "\nActual: " .. m.toString(data.payload)
    end
    return true
  end)
end

function m.sendOnSystemCapabilityUpdated(pAppId, pTimes, pParams)
  if not pTimes then pTimes = 1 end
  if not pParams then pParams = m.buildVideoStreamingCapabilities() end
  local mobileParams = {
    systemCapability = {
      systemCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = pParams
    }
  }
  local hmiParams = m.cloneTable(mobileParams)
  hmiParams.appID = m.getHMIAppId(pAppId)
  actions.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", hmiParams)
  actions.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", mobileParams)
  :Times(pTimes)
  :ValidIf(function(_, data)
      if not utils.isTableEqual(mobileParams, data.payload) then
        return false, "Parameters of the notification are incorrect: \nExpected: " .. utils.toString(mobileParams)
          .. "\nActual: " .. utils.toString(data.payload)
      end
      return true
    end)
end

function m.getHMIParamsWithOutRequests(pParams)
  local params = pParams or utils.cloneTable(hmiDefaultCapabilities)
  params.RC.GetCapabilities.occurrence = 0
  params.UI.GetSupportedLanguages.occurrence = 0
  params.UI.GetCapabilities.occurrence = 0
  params.VR.GetSupportedLanguages.occurrence = 0
  params.VR.GetCapabilities.occurrence = 0
  params.TTS.GetSupportedLanguages.occurrence = 0
  params.TTS.GetCapabilities.occurrence = 0
  params.Buttons.GetCapabilities.occurrence = 0
  params.VehicleInfo.GetVehicleType.occurrence = 0
  params.UI.GetLanguage.occurrence = 0
  params.VR.GetLanguage.occurrence = 0
  params.TTS.GetLanguage.occurrence = 0
  return params
end

function m.ignitionOff()
  local hmiConnection = actions.hmi.getConnection()
  local mobileConnection = actions.mobile.getConnection()
  config.ExitOnCrash = false
  local timeout = 5000
  local function removeSessions()
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  mobileConnection:ExpectEvent(event, "SDL shutdown")
  :Do(function()
    removeSessions()
    StopSDL()
    config.ExitOnCrash = true
  end)
  hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  hmiConnection:ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.getSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end
  end)
  hmiConnection:ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(actions.mobile.getAppsCount())
  local isSDLShutDownSuccessfully = false
  hmiConnection:ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
    utils.cprint(35, "SDL was shutdown successfully")
    isSDLShutDownSuccessfully = true
    mobileConnection:RaiseEvent(event, event)
  end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      mobileConnection:RaiseEvent(event, event)
    end
  end
  actions.run.runAfter(forceStopSDL, timeout + 500)
end

function m.sendOnAppCapabilityUpdated(appCapability, pTimesOnHMI, pAppId)
  if not pAppId then pAppId = 1 end
  if not pTimesOnHMI then pTimesOnHMI = 1 end
  local uiGetCapabilities = hmiDefaultCapabilities.UI.GetCapabilities.params
  if not appCapability then appCapability = {
      appCapability = {
        appCapabilityType = "VIDEO_STREAMING",
        videoStreamingCapability = uiGetCapabilities.systemCapabilities.videoStreamingCapability
      }
    }
  end
  actions.getMobileSession(pAppId):SendNotification("OnAppCapabilityUpdated", appCapability)
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppCapabilityUpdated", appCapability)
  :Times(pTimesOnHMI)
end

local function getVideoDataForStartServicePayload(pData)
  local out = {
    height = pData.preferredResolution.resolutionHeight,
    width = pData.preferredResolution.resolutionWidth,
    videoProtocol = pData.supportedFormats[1].protocol,
    videoCodec = pData.supportedFormats[1].codec
  }
  return out
end

function m.startVideoService(pData, pAppId)
  if not pAppId then pAppId = 1 end
  local videoData = getVideoDataForStartServicePayload(pData)
  local videoPayload = {
    height          = { type = bsonType.INT32,  value = videoData.height },
    width           = { type = bsonType.INT32,  value = videoData.width },
    videoProtocol   = { type = bsonType.STRING, value = videoData.videoProtocol },
    videoCodec      = { type = bsonType.STRING, value = videoData.videoCodec },
  }

  local msg = {
      serviceType = constants.SERVICE_TYPE.VIDEO,
      frameInfo = constants.FRAME_INFO.START_SERVICE,
      encryption = false,
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      binaryData = bson.to_bytes(videoPayload)
    }
  actions.getMobileSession(pAppId):Send(msg)

  actions.getMobileSession():ExpectControlMessage(constants.SERVICE_TYPE.VIDEO, {
    frameInfo = constants.FRAME_INFO.START_SERVICE_ACK,
    encryption = false
  })

  actions.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig",{
    config = {
      height = videoData.height,
      width = videoData.width,
      protocol = videoData.videoProtocol,
      codec = videoData.videoCodec
    }
  })
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  actions.getHMIConnection(pAppId):ExpectRequest("Navigation.StartStream")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function m.startSecureVideoService(pData, pTimes)
  local videoData = getVideoDataForStartServicePayload(pData)

  local videoPayload = {
    height          = { type = bsonType.INT32,  value = videoData.height },
    width           = { type = bsonType.INT32,  value = videoData.width },
    videoProtocol   = { type = bsonType.STRING, value = videoData.videoProtocol },
    videoCodec      = { type = bsonType.STRING, value = videoData.videoCodec }
  }

  actions.getMobileSession():StartSecureService(constants.SERVICE_TYPE.VIDEO, bson.to_bytes(videoPayload))

  actions.getMobileSession():ExpectControlMessage(constants.SERVICE_TYPE.VIDEO, {
    frameInfo = constants.FRAME_INFO.START_SERVICE_ACK,
    encryption = true
  })

  actions.getMobileSession():ExpectHandshakeMessage()
  :Times(pTimes)

  actions.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig", {
    config = {
      height = videoData.height,
      width = videoData.width,
      protocol = videoData.videoProtocol,
      codec = videoData.videoCodec
    }
  })
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  actions.getHMIConnection():ExpectRequest("Navigation.StartStream")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function m.startVideoStreaming(pIsSecure, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = actions.getMobileSession(pAppId)
  local func = mobSession.StartStreaming
  if pIsSecure == true then
    func = mobSession.StartEncryptedStreaming
  end
  func(mobSession, 11, "files/SampleVideo_5mb.mp4")
  actions.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
  utils.cprint(33, "Streaming...")
  utils.wait(1000)
end

function m.stopVideoStreaming(pAppId)
  actions.getMobileSession(pAppId):StopStreaming("files/SampleVideo_5mb.mp4")
  actions.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
end

function m.stopVideoService(pAppId)
  actions.getMobileSession(pAppId):StopService(11)
  actions.getHMIConnection(pAppId):ExpectRequest("Navigation.StopStream")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

local function initSDLCertificates(pCrtsFileName)
  SDL.CRT.set(pCrtsFileName)
end

local function cleanUpCertificates()
  SDL.CRT.clean()
end

function m.securePreconditions()
  actions.preconditions()
  cleanUpCertificates()
  actions.setSDLIniParameter("Protocol", "DTLSv1.0")
  initSDLCertificates("./files/Security/client_credential.pem")
end

function m.securePostconditions()
  actions.postconditions()
  cleanUpCertificates()
end

return m
