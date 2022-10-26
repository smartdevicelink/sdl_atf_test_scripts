---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local apiLoader = require("modules/api_loader")
local api = apiLoader.init("data/MOBILE_API.xml")
local schema = api.interface[next(api.interface)]

--[[ Module ]]
local m = {}

--[[ Proxy Functions ]]
m.preconditions = actions.preconditions
m.start = actions.start
m.registerNoPTU = actions.app.registerNoPTU
m.activate = actions.app.activate
m.postconditions = actions.postconditions

--[[ Local Variables ]]
local DefaultTimeout = actions.sdl.getSDLIniParameter("DefaultTimeout")
local DefaultTimeoutCompensation = actions.sdl.getSDLIniParameter("DefaultTimeoutCompensation")
local GeneralTimeout = DefaultTimeout + DefaultTimeoutCompensation
local respTimeoutCompensation = 3000
local calcAccuracy = 1000

--[[ Common Variables ]]
m.timeToSendResp = 2000
m.sendUIresp = true
m.sendVRresp = true
m.notSendUIresp = false
m.notSsendVRresp = false
m.noAdditionalTimeout = 0

--[[ Local Functions ]]
local function getDefaultValueFromAPI(pFunctionName, pParamName)
  local defvalue = schema.type["request"].functions[pFunctionName].param[pParamName].defvalue
  if not defvalue then
    print("Default value was not found in API for function '" .. pFunctionName
      .. "' and parameter '" .. pParamName .. "'")
    defvalue = 0
  end
  print("Default value: " .. defvalue)
  return defvalue
end

--[[ Common Functions ]]
function m.putFile(pFileName)
  local cid = actions.mobile.getSession():SendRPC(
    "PutFile",
    {syncFileName = pFileName, fileType = "GRAPHIC_PNG", persistentFile = false, systemFile = false},
  "files/icon.png")

  actions.mobile.getSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function m.alert(params)
  local AlertDuration
  if params.duration then
    AlertDuration = params.duration
  else
    AlertDuration = getDefaultValueFromAPI("Alert", "duration")
  end
  local RespTimeout = GeneralTimeout + AlertDuration
  local RequestTime
  local RespTime
  local TimeBetweenReqRes

  if params.ttsChunks then
    actions.hmi.getConnection():ExpectRequest("TTS.Speak")
    :Do(function(_,data)
        local function SpeakResp()
          actions.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end
        RUN_AFTER(SpeakResp, m.timeToSendResp)
      end)
  end

  local cid = actions.mobile.getSession():SendRPC("Alert", params)
  RequestTime = timestamp()

  actions.hmi.getConnection():ExpectRequest("UI.Alert")

  actions.mobile.getSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(RespTimeout + respTimeoutCompensation)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - calcAccuracy and TimeBetweenReqRes < RespTimeout + calcAccuracy then
        return true
      else
        return false, "SDL triggers timeout earlier then expected("
          .. tostring(RespTimeout) .." sec), after " .. tostring(TimeBetweenReqRes)
          .. " sec.\n SDL must use Alert duration + default timeout in case of absence softButtons."
      end
    end)
end

function m.slider(params)
  local SliderDuration
  if params.timeout then
    SliderDuration = params.timeout
  else
    SliderDuration = getDefaultValueFromAPI("Slider", "timeout")
  end
  local RespTimeout = GeneralTimeout + SliderDuration
  local RequestTime
  local RespTime
  local TimeBetweenReqRes
  local cid = actions.mobile.getSession():SendRPC("Slider", params)
  RequestTime = timestamp()
  actions.hmi.getConnection():ExpectRequest("UI.Slider")
  actions.mobile.getSession():ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(RespTimeout + respTimeoutCompensation)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - calcAccuracy and TimeBetweenReqRes < RespTimeout + calcAccuracy then
        return true
      else
        return false, "SDL triggers timeout earlier then expected(".. tostring(RespTimeout) .." sec), after "
          .. tostring(TimeBetweenReqRes) .. " sec. \n SDL must use Slider timeout + default timeout."
      end
    end)
end

function m.scrollableMessage(params)
  local ScrMesDuration
  if params.timeout then
    ScrMesDuration = params.timeout
  else
    ScrMesDuration = getDefaultValueFromAPI("ScrollableMessage", "timeout")
  end
  local RespTimeout = GeneralTimeout + ScrMesDuration
  local RequestTime
  local RespTime
  local TimeBetweenReqRes
  local cid = actions.mobile.getSession():SendRPC("ScrollableMessage", params)
  RequestTime = timestamp()
  actions.hmi.getConnection():ExpectRequest("UI.ScrollableMessage")
  actions.mobile.getSession():ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(RespTimeout + respTimeoutCompensation)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - calcAccuracy and TimeBetweenReqRes < RespTimeout + calcAccuracy then
        return true
      else
        return false, "SDL triggers timeout earlier then expected(".. tostring(RespTimeout) .." sec), after "
          .. tostring(TimeBetweenReqRes) .. " sec. \n SDL must use ScrollableMessage timeout + default timeout."
      end
    end)
end

function m.createInteractionChoiceSet()
  local cid = actions.mobile.getSession():SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = 100,
      choiceSet = {
        {
          choiceID = 100,
          menuName ="Choice100",
          vrCommands = {
            "Choice100",
          }
        }
      }
    })
  actions.hmi.getConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_,data)
      actions.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  actions.mobile.getSession():ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
end

function m.performInteraction(params, isUIrespSent, isVRrespSent, additionalTimeout)
  local PIDuration
  local RequestTime
  local RespTime
  local TimeBetweenReqRes
  local RespTimeout
  local mainParams = {
    initialText = "StartPerformInteraction",
    initialPrompt = {
      {
        text = "Make your choice",
        type = "TEXT"
      }
    },
    interactionChoiceSetIDList = { 100 },
    helpPrompt = {
      {
        text = "Help Prompt",
        type = "TEXT",
      }
    },
    timeoutPrompt = {
      {
        text = "Time out",
        type = "TEXT",
      }
    },
    interactionLayout = "ICON_ONLY"
  }

  for param, value in pairs(params) do
    mainParams[param] = value
  end

  PIDuration = params.timeout or getDefaultValueFromAPI("PerformInteraction", "timeout")
  RespTimeout = GeneralTimeout + PIDuration + additionalTimeout
  local cid = actions.mobile.getSession():SendRPC("PerformInteraction", mainParams)
  RequestTime = timestamp()
  actions.hmi.getConnection():ExpectRequest("VR.PerformInteraction")
  :Do(function(_,data)
      if isVRrespSent == true then
        local function RespVR()
          if mainParams.interactionMode == "BOTH" then
            actions.hmi.getConnection():SendError(data.id, data.method, "ABORTED", "error message")
          else
            actions.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          end
        end
        RUN_AFTER(RespVR, m.timeToSendResp)
      end
    end)
  actions.hmi.getConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function(_,data)
      if isUIrespSent == true then
        local function RespUI()
          actions.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end
        RUN_AFTER(RespUI, m.timeToSendResp)
      end
    end)
  actions.mobile.getSession():ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(RespTimeout + respTimeoutCompensation)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - calcAccuracy and TimeBetweenReqRes < RespTimeout + calcAccuracy then
        return true
      else
        return false, "SDL triggers timeout earlier then expected(".. tostring(RespTimeout) .." sec), after "
          .. tostring(TimeBetweenReqRes) .. " sec. \n SDL must use PI timeout + default timeout."
      end
    end)
end

return m
