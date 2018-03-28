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
local commonFunctions = require('user_modules/shared_testcases/commonFunctions') --add
local commonTestCases = require('user_modules/shared_testcases/commonTestCases') --add

--[[ Module ]]
local m = actions

--[[ Variables ]]
local ptuTable = {}
local hmiAppIds = {}

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pIconResumed - Existence of apps icon at system
--! @return: none
--]]
function m.registerApp(pAppId, pIconResumed, pReconnection, pIcon)
  if not pAppId then pAppId = 1 end
  if not pIcon then pIcon = "icon.png" end
  local mobSession = m.getMobileSession(pAppId)
  local function RegisterApp()
    local corId = mobSession:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
    local iconValue
    if pIconResumed == true then
      iconValue = m.getPathToFileInStorage(pIcon)
    elseif pIconResumed == false then
      iconValue = ""
    end
      test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName, icon = iconValue } })
      :Do(function(_, d1)
          hmiAppIds[m.getAppID(pAppId)] = d1.params.application.appID
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS", iconResumed = pIconResumed })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
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

--function m.DeleteFile( pIcon, pAppId )
  --local mobSession = m.getMobileSession(pAppId)
  --local cid = mobSession:SendRPC("DeleteFile",
  --{ syncFileName = pIcon })
  ---EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
    --{
     --fileName = pIcon,
     --fileType = "GRAPHIC_PNG",
     --appID = 1 })
  --mobSession:ExpectResponse( cid, { success = true, resultCode = "SUCCESS", info = nil })
--end


--Description: unregisterAppInterface successfully
  --pAppId - application number (1, 2, etc.)
function m.unregisterAppInterface(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local corId = mobSession:SendRPC("UnregisterAppInterface", { })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    { appID = m.getHMIAppId(), unexpectedDisconnect = false })
  mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--Description: Set all parameter for PutFile
local function putFileAllParams()
  local temp = {
    syncFileName = "icon.png",
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false,
    offset = 0,
    length = 11600
  }
  return temp
end

--Description: PutFile successfully
  --paramsSend: Parameters will be sent to SDL
  --file: path to file will be used to send to SDL
  --pAppId - application number (1, 2, etc.)
function m.putFile(paramsSend, file, pAppId)
  if paramsSend then
    paramsSend = paramsSend
  else paramsSend =  putFileAllParams()
  end
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local cid
  if file ~= nil then
    cid = mobSession:SendRPC("PutFile",paramsSend, file)
  else
    cid = mobSession:SendRPC("PutFile",paramsSend, "files/icon.png")
  end

  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end



function m.getPathToFileInStorage(fileName)
  return commonPreconditions:GetPathToSDL() .. "storage/"
  .. m.getAppID() .. "_"
  .. utils.getDeviceMAC() .. "/" .. fileName
end

--Description: setAppIcon successfully
  --paramsSend: Parameters will be sent to SDL
  --pAppId - application number (1, 2, etc.)
function m.setAppIcon(params, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  local cid = mobSession:SendRPC("SetAppIcon", params.requestParams)
  params.requestUiParams.appID = m.getHMIAppId()
  EXPECT_HMICALL("UI.SetAppIcon", params.requestUiParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function(_, _)
    -- HMI does not respond
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})

  commonTestCases:DelayedExp(11000)
end

function m.connectMobile()
  test:connectMobile()
end

return m
