---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local constants = require('protocol_handler/ford_protocol_constants')
local consts = require("user_modules/consts")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Module ]]
local m = {}

--[[ Constants ]]
m.requestNames = {
  [10] = { start = "Navigation.StartAudioStream", stop = "Navigation.StopAudioStream" },
  [11] = { start = "Navigation.StartStream", stop = "Navigation.StopStream" }
}

--[[ Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.setSDLIniParameter = actions.sdl.setSDLIniParameter
m.start = actions.start
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp

m.app = actions.app
m.hmi = actions.hmi
m.mobile = actions.mobile
m.sdl = actions.sdl
m.run = actions.run
m.wait = actions.run.wait
m.color = consts.color


--[[ Common Functions ]]
function m.sendErrorResponse(pData, pDelay)
  local function sendResponse()
    m.hmi.getConnection():SendError(pData.id, pData.method, "REJECTED", "Request is rejected")
  end
  m.run.runAfter(sendResponse, pDelay)
end

function m.sendSuccessResponse(pData, pDelay)
  local function sendResponse()
    m.hmi.getConnection():SendResponse(pData.id, pData.method, "SUCCESS", {})
  end
  m.run.runAfter(sendResponse, pDelay)
end

local function registerExpectEndService()
  local session = m.mobile.getSession()
  function session:ExpectEndService(pServiceId)
    local event = m.run.createEvent()
    event.matches = function(_, data)
      return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
        data.serviceType == pServiceId and
        data.sessionId == self.sessionId and
        data.frameInfo == constants.FRAME_INFO.END_SERVICE
    end
    return session:ExpectEvent(event, "End Service Event")
  end
end

local createSession_Orig = m.mobile.createSession

function m.mobile.createSession(...)
  local session = createSession_Orig(...)
  registerExpectEndService()
  return session
end

return m
