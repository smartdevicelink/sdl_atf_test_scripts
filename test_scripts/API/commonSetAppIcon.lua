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

--[[ Module ]]
local m = actions

--[[ Variables ]]
local ptuTable = {}
local hmiAppIds = {}

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.registerApp(pAppId, pIconResumed)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
      test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
          hmiAppIds[m.getConfigAppParams(pAppId).appID] = d1.params.application.appID
          test.hmiConnection:ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
          :Times(2)
          test.hmiConnection:ExpectRequest("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              test.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptuTable = utils.jsonFileToTable(d2.params.file)
            end)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS", iconResumed = pIconResumed })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

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
    syncFileName ="icon.png",
    fileType ="GRAPHIC_PNG",
    persistentFile =false,
    systemFile = false,
    offset =0,
    length =11600
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

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
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
end
