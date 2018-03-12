---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local Test = require('user_modules/connecttest_PutFile')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')


--[[ Module ]]
local m = actions
local f = Test
local u = commonSmoke

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

function u.unregisterAppInterface(pAppId, pIconResumed)
  local corId = mobileSession:SendRPC("UnregisterAppInterface", { })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    { appID = commonSmoke.getHMIAppId(), unexpectedDisconnect = false })
  mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS", iconResumed = pIconResumed })
end

--Description: Set all parameter for PutFile
function f.putFileAllParams()
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

--Description: Set all parameter for Show
  --syncFileNameValue: image file name will be use to Show
function f.showAllParams(syncFileNameValue)
  local temp = {
          mediaClock = "12:34",
          mainField1 = "Show Line 1",
          mainField2 = "Show Line 2",
          mainField3 = "Show Line 3",
          mainField4 = "Show Line 4",
          graphic =
          {
            value = syncFileNameValue,
            imageType = "DYNAMIC"
          },
          softButtons =
          {
             {
              text = "Close",
              systemAction = "KEEP_CONTEXT",
              type = "BOTH",
              isHighlighted = true,
              image =
              {
                 imageType = "DYNAMIC",
                 value = syncFileNameValue
              },
              softButtonID = 1
             }
           },
          secondaryGraphic =
          {
            value = syncFileNameValue,
            imageType = "DYNAMIC"
          },
          statusBar = "status bar",
          mediaTrack = "Media Track",
          alignment = "CENTERED",
          customPresets =
          {
            "Preset1",
            "Preset2",
            "Preset3"
          }
        }

  return temp
end

--Description: Set expected parameter for Show request
  --syncFileNameValue: image file name will be use to Show
  --pathToStorage: path to storage where will be used to store image
function f.exShowAllParams(syncFileNameValue, pathToStorage)
  local temp = {
          alignment = "CENTERED",
          customPresets =
          {
            "Preset1",
            "Preset2",
            "Preset3"
          },
          graphic =
          {
            imageType = "DYNAMIC",
            value = pathToStorage..syncFileNameValue
          },
          secondaryGraphic =
          {
            imageType = "DYNAMIC",
            value = pathToStorage..syncFileNameValue
          },
          showStrings =
          {
            {
            fieldName = "mainField1",
            fieldText = "Show Line 1"
            },
            {
            fieldName = "mainField2",
            fieldText = "Show Line 2"
            },
            {
            fieldName = "mainField3",
            fieldText = "Show Line 3"
            },
            {
            fieldName = "mainField4",
            fieldText = "Show Line 4"
            },
            {
            fieldName = "mediaClock",
            fieldText = "12:34"
            },
            {
              fieldName = "mediaTrack",
              fieldText = "Media Track"
            },
            {
              fieldName = "statusBar",
              fieldText = "status bar"
            }
          },
          softButtons =
          {
             {
              text = "Close",
              systemAction = "KEEP_CONTEXT",
              type = "BOTH",
              isHighlighted = true,
              image =
              {
                 imageType = "DYNAMIC",
                 value = pathToStorage..syncFileNameValue
              },
              softButtonID = 1
             }
           }
        }

  return temp
end

--Description: PutFile successfully
  --paramsSend: Parameters will be sent to SDL
  --file: path to file will be used to send to SDL
function Test:putFile(paramsSend, file)
  local cid
  if file ~= nil then
    cid = mobileSession:SendRPC("PutFile",paramsSend, file)
  else
    cid = mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")
  end

  EXPECT_RESPONSE(cid, { success = true, resultCode = SUCCESS })
end

--Description: Check file will be put to appropriate SDL application folder.
  --fileName: File reference name.
  --file: path to file will be used to send to SDL
function Test:putFileToStorage(fileName, file)
  local paramsSend = putFileAllParams()
  paramsSend.syncFileName = fileName

  --mobile side: sending PutFile request
  local cid = mobileSession:SendRPC("PutFile",paramsSend, "files/"..file)

  --mobile side: expected PutFile response
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    --SDL store FileName_1 into sub-directory of AppStorageFolder related to app
    if file_check(storagePath..fileName) ~= true then
      print(" \27[36m Can not found file: "..fileName.." \27[0m ")
      return false
    else
      return true
    end
  end)
end

local function setAppIcon(params, self)
  local cid = self.mobileSession:SendRPC("SetAppIcon", params.requestParams)
  params.requestUiParams.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("UI.SetAppIcon", params.requestUiParams)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end
