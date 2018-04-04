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

function m.setForceProtectedServiceParam(pParamValue)
  m.setSDLIniParameter("ForceProtectedService", pParamValue)
end

function m.getAppID(pAppId)
  return m.getConfigAppParams(pAppId).appID
end

return m
