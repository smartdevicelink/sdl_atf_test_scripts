---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local runner = require('user_modules/script_runner')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3
config.checkAllValidations = true

--[[ Shared Functions ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.start = actions.start
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.activateApp = actions.activateApp
m.registerApp = actions.registerAppWOPTU
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.getHMIConnection = actions.hmi.getConnection
m.getMobileSession = actions.getMobileSession
m.getAppsCount = actions.getAppsCount
m.getHMIAppId = actions.getHMIAppId
m.getConfigAppParams = actions.getConfigAppParams
m.cleanSessions = actions.mobile.closeSession
m.null = actions.json.null
m.spairs = utils.spairs
m.wait = utils.wait
m.cloneTable = utils.cloneTable

m.failedTCs = {}

m.events = {
  activateApp = {
    name = "Activation",
    func = function(pAppId)
      local requestId = m.getHMIConnection():SendRequest("SDL.ActivateApp", {
        appID = m.getHMIAppId(pAppId) })
      m.getHMIConnection():ExpectResponse(requestId)
    end
  },
  deactivateApp = {
    name = "De-activation",
    func = function(pAppId)
      m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
        appID = m.getHMIAppId(pAppId) })
    end
  },
  deactivateHMI = {
    name = "HMI De-activation",
    func = function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "DEACTIVATE_HMI",
        isActive = true })
    end
  },
  activateHMI = {
    name = "HMI Activation",
    func = function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "DEACTIVATE_HMI",
        isActive = false })
    end
  },
  exitApp = {
    name = "User Exit",
    func = function(pAppId)
      m.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication", {
        appID = m.getHMIAppId(pAppId),
        reason = "USER_EXIT" })
    end
  },
  phoneCallStart = {
    name = "Phone call start",
    func = function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "PHONE_CALL",
        isActive = true })
    end
  },
  phoneCallEnd = {
    name = "Phone call end",
    func = function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "PHONE_CALL",
        isActive = false })
    end
  }
}

function m.setAppConfig(pAppId, pAppHMIType, pIsMedia)
  m.getConfigAppParams(pAppId).appHMIType = { pAppHMIType }
  m.getConfigAppParams(pAppId).isMediaApplication = pIsMedia
end

local function checkAudioSS(pTC, pEvent, pExpAudioSS, pActAudioSS)
  if pActAudioSS ~= pExpAudioSS then
    if m.failedTCs[pTC] == nil then
      m.failedTCs[pTC] = ""
    else
      m.failedTCs[pTC] = m.failedTCs[pTC] .. "\n\t"
    end
    local msg = pEvent .. ": audioStreamingState: expected " .. tostring(pExpAudioSS)
      .. ", actual value: " .. tostring(pActAudioSS)
    m.failedTCs[pTC] = m.failedTCs[pTC] .. msg
    return false, msg
  end
  return true
end

local function checkVideoSS(pTC, pEvent, pExpVideoSS, pActVideoSS)
  if pActVideoSS ~= pExpVideoSS then
    if m.failedTCs[pTC] == nil then
      m.failedTCs[pTC] = ""
    else
      m.failedTCs[pTC] = m.failedTCs[pTC] .. "\n\t"
    end
    local msg = pEvent .. ": videoStreamingState: expected " .. tostring(pExpVideoSS)
      .. ", actual value: " .. tostring(pActVideoSS)
    m.failedTCs[pTC] = m.failedTCs[pTC] .. msg
    return false, msg
  end
  return true
end

local function checkHMILevel(pTC, pEvent, pExpHMILvl, pActHMILvl)
  if pActHMILvl ~= pExpHMILvl then
    if m.failedTCs[pTC] == nil then
      m.failedTCs[pTC] = ""
    else
      m.failedTCs[pTC] = m.failedTCs[pTC] .. "\n\t"
    end
    local msg = pEvent .. ": hmiLevel: expected " .. tostring(pExpHMILvl) .. ", actual value: " .. tostring(pActHMILvl)
    m.failedTCs[pTC] = m.failedTCs[pTC] .. msg
    return false, msg
  end
  return true
end

function m.checkHMIStatus(pTC, pEventName, pAppId, pExpectVal)
  local exp = m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  if pExpectVal.a then
    exp:ValidIf(function(_, data)
        return checkAudioSS(pTC, pEventName, pExpectVal.a, data.payload.audioStreamingState)
      end)
  end
  if pExpectVal.v then
    exp:ValidIf(function(_, data)
        return checkVideoSS(pTC, pEventName, pExpectVal.v, data.payload.videoStreamingState)
      end)
  end
  if pExpectVal.l then
    exp:ValidIf(function(_, data)
        return checkHMILevel(pTC, pEventName, pExpectVal.l, data.payload.hmiLevel)
      end)
  end
  if not (pExpectVal.a and pExpectVal.v and pExpectVal.l) then
    exp:Times(0)
  end
end

function m.printFailedTCs()
  for tc, msg in m.spairs(m.failedTCs) do
    utils.cprint(35, string.format("%03d", tc), msg)
  end
end

return m
