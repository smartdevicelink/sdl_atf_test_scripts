---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local json = require("modules/json")
local test = require("user_modules/dummy_connecttest")
local SDL = require("SDL")

--[[ Module ]]
local c = actions

--[[ Variables ]]
local wrnMsg
c.language = "EN-US"

--[[ Common Functions ]]
function c.registerAppWithOnDD(pAppId)
  c.registerApp(pAppId)
  c.getMobileSession(pAppId):ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
end

function c.expOnDriverDistraction(pState, pLockScreenDismissalEnabled, pAppId)
  c.getMobileSession(pAppId):ExpectNotification("OnDriverDistraction", { state = pState })
  :ValidIf(function(_, d)
      if d.payload.state == "DD_OFF" and d.payload.lockScreenDismissalEnabled ~= nil then
        return false, d.payload.state .. ": Parameter `lockScreenDismissalEnabled` is not expected"
      end
      if d.payload.state == "DD_ON" then
        if pLockScreenDismissalEnabled == nil and d.payload.lockScreenDismissalEnabled ~= nil then
          return false, d.payload.state .. ": Parameter `lockScreenDismissalEnabled` is not expected"
        end
        if pLockScreenDismissalEnabled ~= d.payload.lockScreenDismissalEnabled then
          return false, d.payload.state .. ": Parameter `lockScreenDismissalEnabled` is not the same as expected"
        end
      end
      return true
    end)
  :ValidIf(function(_, d)
      if d.payload.lockScreenDismissalEnabled == true then
        if d.payload.lockScreenDismissalWarning == nil then
          return false, d.payload.state .. "(" .. tostring(d.payload.lockScreenDismissalEnabled) .. ")"
            .. ": Parameter `lockScreenDismissalWarning` is missing"
        elseif d.payload.lockScreenDismissalWarning ~= wrnMsg then
          return false, d.payload.state .. "(" .. tostring(d.payload.lockScreenDismissalEnabled) .. ")"
            .. ": The value for parameter `lockScreenDismissalWarning` is not the same as expected"
        end
      elseif d.payload.lockScreenDismissalWarning ~= nil then
        return false, d.payload.state .. "(" .. tostring(d.payload.lockScreenDismissalEnabled) .. ")"
          .. ": Parameter `lockScreenDismissalWarning` is not expected"
      end
      return true
    end)
end

function c.onDriverDistraction(pState, pLockScreenDismissalEnabled, pAppId)
  if not pAppId then pAppId = 1 end
  c.getHMIConnection():SendNotification("UI.OnDriverDistraction", { state = pState })
  c.expOnDriverDistraction(pState, pLockScreenDismissalEnabled, pAppId)
end

local preconditionsOrig = c.preconditions
function c.preconditions()
  preconditionsOrig()
  SDL.PreloadedPT.backup()
end

local postconditionsOrig = c.postconditions
function c.postconditions()
  postconditionsOrig()
  SDL.PreloadedPT.restore()
end

local function setLockScreenWrnMsg(pMessages)
  local lang = string.lower(c.language)
  local warnSec = pMessages["LockScreenDismissalWarning"]
  if warnSec == nil then
    test:FailTestCase("'LockScreenDismissalWarning' message section is not defined in 'sdl_preloaded_pt' file")
  else
    local msg = "'LockScreenDismissalWarning' message for '" .. lang .. "' is not defined in 'sdl_preloaded_pt' file"
    if lang == "en-us" and warnSec.languages[lang] == nil then
      test:FailTestCase(msg)
      return
    end
    if warnSec.languages[lang] == nil then
      utils.cprint(35, msg)
      utils.cprint(35, "'en-us' should be used instead")
      lang = "en-us"
    end
    wrnMsg = warnSec.languages[lang].textBody
  end
end

function c.updatePreloadedPT(pLockScreenDismissalEnabled, pUpdateFunc)
  local pt = SDL.PreloadedPT.get()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.module_config.lock_screen_dismissal_enabled = pLockScreenDismissalEnabled
  if pUpdateFunc then
    pUpdateFunc(pt)
  end
  setLockScreenWrnMsg(pt.policy_table.consumer_friendly_messages.messages)
  SDL.PreloadedPT.set(pt)
end

local function deactivateAppToLimited()
  c.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = c.getHMIAppId() })
  c.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function deactivateAppToBackground()
  c.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "AUDIO_SOURCE", isActive = true
  })
  c.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

c.hmiLevel = {
  [1] = { name = "NONE", func = function() end },
  [2] = { name = "FULL", func = c.activateApp },
  [3] = { name = "LIMITED", func = deactivateAppToLimited },
  [4] = { name = "BACKGROUND", func = deactivateAppToBackground }
}

c.pairs = utils.spairs

return c
