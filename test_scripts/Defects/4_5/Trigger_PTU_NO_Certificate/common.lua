---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local security = require("user_modules/sequences/security")
local utils = require("user_modules/utils")

--[[ Module ]]
local m = actions

m.frameInfo = security.frameInfo
m.delayedExp = utils.wait
m.readFile = utils.readFile

local function registerGetSystemTimeNotification()
  m.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
  m.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemTime")
  :Do(function(_, d)
      local function getSystemTime()
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
      m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { systemTime = getSystemTime() })
    end)
  :Times(AnyNumber())
  :Pin()
end

local startOrig = m.start

function m.start(pHMIParams)
	startOrig(pHMIParams)
	:Do(function()
			registerGetSystemTimeNotification()
		end)
end

function m.setForceProtectedServiceParam(pParamValue)
  m.setSDLIniParameter("ForceProtectedService", pParamValue)
end

function m.getAppID(pAppId)
  return m.getConfigAppParams(pAppId).fullAppID
end

return m
