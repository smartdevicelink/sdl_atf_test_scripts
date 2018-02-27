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
local m = {}

-- Proxies for the inherited objects
utils.inheritObjects(m, actions)
utils.inheritObjects(m, security)

function m.setForceProtectedServiceParam(pParamValue)
  m.setSDLIniParameter("ForceProtectedService", pParamValue)
end

function m.delayedExp(pTimeOut)
  utils.wait(pTimeOut)
end

function m.readFile(pFilePath)
	return utils.readFile(pFilePath)
end

function m.getAppID(pAppId)
  return m.getConfigAppParams(pAppId).appID
end

return m
