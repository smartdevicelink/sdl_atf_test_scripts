---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")

--[[ Module ]]
local m = actions

m.failedTCs = {}

m.wait = utils.wait
m.cloneTable = utils.cloneTable
m.registerApp = m.registerAppWOPTU

function m.activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local requestId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  test.hmiConnection:ExpectResponse(requestId)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
  utils.wait()
end

function m.setAppConfig(pAppId, pAppHMIType, pIsMedia)
  m.getConfigAppParams(pAppId).appHMIType = { pAppHMIType }
  m.getConfigAppParams(pAppId).isMediaApplication = pIsMedia
end

function m.cleanSessions()
  for i = 1, m.getAppsCount() do
    test.mobileSession[i]:StopRPC()
    :Do(function(_, d)
        utils.cprint(35, "Mobile session " .. d.sessionId .. " deleted")
        test.mobileSession[i] = nil
      end)
  end
  utils.wait()
end

function m.spairs(pTbl)
  local keys = {}
  for k in pairs(pTbl) do
    keys[#keys+1] = k
  end
  local function getStringKey(pKey)
    return tostring(string.format("%03d", pKey))
  end
  table.sort(keys, function(a, b) return getStringKey(a) < getStringKey(b) end)
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], pTbl[keys[i]]
    end
  end
end

function m.checkAudioSS(pTC, pEvent, pExpAudioSS, pActAudioSS)
  if pActAudioSS ~= pExpAudioSS then
    if m.failedTCs[pTC] == nil then
      m.failedTCs[pTC] = ""
    else
      m.failedTCs[pTC] = m.failedTCs[pTC] .. "\n\t"
    end
    local msg = pEvent .. ": audioStreamingState: expected " .. pExpAudioSS
      .. ", actual value: " .. tostring(pActAudioSS)
    m.failedTCs[pTC] = m.failedTCs[pTC] .. msg
    return false, msg
  end
  return true
end

function m.checkVideoSS(pTC, pEvent, pExpVideoSS, pActVideoSS)
  if pActVideoSS ~= pExpVideoSS then
    if m.failedTCs[pTC] == nil then
      m.failedTCs[pTC] = ""
    else
      m.failedTCs[pTC] = m.failedTCs[pTC] .. "\n\t"
    end
    local msg = pEvent .. ": videoStreamingState: expected " .. pExpVideoSS
      .. ", actual value: " .. tostring(pActVideoSS)
    m.failedTCs[pTC] = m.failedTCs[pTC] .. msg
    return false, msg
  end
  return true
end

function m.checkHMILevel(pTC, pEvent, pExpHMILvl, pActHMILvl)
  if pActHMILvl ~= pExpHMILvl then
    if m.failedTCs[pTC] == nil then
      m.failedTCs[pTC] = ""
    else
      m.failedTCs[pTC] = m.failedTCs[pTC] .. "\n\t"
    end
    local msg = pEvent .. ": hmiLevel: expected " .. pExpHMILvl .. ", actual value: " .. tostring(pActHMILvl)
    m.failedTCs[pTC] = m.failedTCs[pTC] .. msg
    return false, msg
  end
  return true
end

function m.printFailedTCs()
  for tc, msg in m.spairs(m.failedTCs) do
    utils.cprint(35, string.format("%03d", tc), msg)
  end
end

return m
