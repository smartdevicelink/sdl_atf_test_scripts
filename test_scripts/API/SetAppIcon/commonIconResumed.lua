---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require('mobile_session')

--[[ Module ]]
local m = actions

--[[ Variables ]]

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

--[[ @getIconValueForResumption: Get path of app icon from storage
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: app icon path
--]]
function m.getIconValueForResumption(pAppId)
  if not pAppId then pAppId = 1 end
  return commonPreconditions:GetPathToSDL() .. "storage/" .. m.getConfigAppParams(pAppId).fullAppID
end

--[[ @registerAppWOPTU: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pIconResumed - apps icon was resumed at system or is not resumed
--! pReconnection - re-register mobile application
--! @return: none
--]]
function m.registerAppWOPTU(pAppId, pIconResumed, pReconnection)
  if not pAppId then pAppId = 1 end
  local pIconValue
  if pIconResumed == true then pIconValue = m.getIconValueForResumption(pAppId) end
  local mobSession = m.getMobileSession(pAppId)
  local function RegisterApp()
    local corId = mobSession:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
      test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered", {
        application = {
          appName = config["application" .. pAppId].registerAppInterfaceParams.appName,
          icon = pIconValue
        }
      })
      :ValidIf(function(_,data)
        if false == pIconResumed and
          data.params.application.icon then
          return false, "BC.OnAppRegistered notification contains unexpected parameter: icon "
        end
        return true
      end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS", iconResumed = pIconResumed })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus", {
            hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
          })
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end
  if pReconnection == true then
    RegisterApp()
  else
    mobSession:StartService(7)
    :Do(function()
        RegisterApp()
      end)
  end
end

--[[ @unregisterAppInterface: Mobile application unregistration
--! @parameters:
--! pAppId - Application number (1, 2, etc.)
--! @return: none
--]]
function m.unregisterAppInterface(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local corId = mobSession:SendRPC("UnregisterAppInterface", { })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {
    appID = m.getHMIAppId(pAppId), unexpectedDisconnect = false
  })
  mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
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

--[[ @setAppIcon: Successful Processing of SetAppIcon RPC
--! @parameters:
--! pParams - Parameters for SetAppIcon RPC
--! pAppId - Application number (1, 2, etc.)
--! @return: none
--]]
function m.setAppIcon(pParams, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local cid = mobSession:SendRPC("SetAppIcon", pParams.requestParams)
  pParams.requestUiParams.appID = m.getHMIAppId()
  EXPECT_HMICALL("UI.SetAppIcon", pParams.requestUiParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ @closeConnection: Close mobile connection successfully
--! @parameters: none
--! @return: none
--]]
function m.closeConnection()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  actions.mobile.disconnect()
  actions.run.wait(1000)
end

--[[ @openConnection: Open mobile connection successfully
--! @parameters: none
--! return: none
--]]
function m.openConnection()
  actions.mobile.connect()
  :Do(function()
      m.mobile.createSession():StartRPC()
    end)
end

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

return m
