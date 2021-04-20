---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")

--[[ Module ]]
local m = actions

m.cloneTable = utils.cloneTable

--[[ @getPathToFileInStorage: Get path of app icon from storage
--! @parameters:
--! pFileName - Name of file
--! pAppId - application number (1, 2, etc.)
--! @return: app icon path
--]]
function m.getPathToFileInStorage(pFileName, pAppId)
  if not pAppId then pAppId = 1 end
  return commonPreconditions:GetPathToSDL() .. "storage/"
    .. m.getConfigAppParams(pAppId).fullAppID .. "_"
    .. utils.getDeviceMAC() .. "/" .. pFileName
end

--[[ @getPutFileAllParams: get all parameter for PutFile
--! @parameters: none
--! @return: parameters for PutFile
--]]
local function getPutFileAllParams()
  return {
    syncFileName = "icon.png",
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false,
    offset = 0,
    length = 11600
  }
end

--[[ @putFile: Successful processing PutFile RPC
--! @parameters:
--! pParamsSend - parameters for PutFile RPC
--! pFile - file will be used to send to SDL
--! pAppId - Application number (1, 2, etc.)
--! @return: none
--]]
function m.putFile(pParamsSend, pFile, pAppId)
  if pParamsSend then
    pParamsSend = pParamsSend
  else
    pParamsSend = getPutFileAllParams()
  end
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local cid
  if pFile ~= nil then
    cid = mobSession:SendRPC("PutFile", pParamsSend, pFile)
  else
    cid = mobSession:SendRPC("PutFile", pParamsSend, "files/icon_png.png")
  end

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ @AddSubMenu: Successful processing AddSubMenu RPC
--! @parameters:
--! pParams - Parameters for AddSubMenu RPC
--! @return: none
--]]
function m.addSubMenu(pParams)
  local mobSession = m.getMobileSession()
  local cid = mobSession:SendRPC("AddSubMenu", pParams.requestParams)

  pParams.responseUiParams.appID = m.getHMIAppId()
  EXPECT_HMICALL("UI.AddSubMenu", pParams.responseUiParams)
  :Do(function(_,data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  mobSession:ExpectNotification("OnHashChange")
end

local preconditionsOrig = m.preconditions

function m.preconditions()
  preconditionsOrig()
  local storage = commonPreconditions:GetPathToSDL() .. "storage/*"
  assert(os.execute("rm -rf " .. storage))
end

return m
