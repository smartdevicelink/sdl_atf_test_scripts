---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local hmi_values = require('user_modules/hmi_values')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require ('user_modules/utils')

--[[ Module ]]
local m = actions

m.type = "FILE"

local preconditionsOrig = m.preconditions

--[[ @preconditions: Expand initial precondition with removing storage folder
--! @parameters: none
--! return: none
--]]
function m.preconditions()
  preconditionsOrig()
  local storage = commonPreconditions:GetPathToSDL() .. "storage/*"
  assert(os.execute("rm -rf " .. storage))
end

local startOrigin = m.start
function m.start()
  local params = hmi_values.getDefaultHMITable()
  table.insert(params.TTS.GetCapabilities.params.speechCapabilities, m.type)
  startOrigin(params)
end

function m.putFile(params, pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobileSession = m.getMobileSession(pAppId, self);
  local cid = mobileSession:SendRPC("PutFile", params.requestParams, params.filePath)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function m.getPathToFileInStorage(fileName)
  return commonPreconditions:GetPathToSDL() .. "storage/"
  .. m.getMobileAppId() .. "_"
  .. m.getDeviceMAC() .. "/" .. fileName
end

m.getDeviceName = utils.getDeviceName

m.getDeviceMAC = utils.getDeviceMAC

function m.getMobileAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams.fullAppID
end

return m
