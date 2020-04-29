
config.defaultProtocolVersion = 4

Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local events = require('events')
local mobile_session = require('mobile_session')

local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require ('/user_modules/shared_testcases/commonFunctions')
local srcPath = config.pathToSDL .. "smartDeviceLink.ini"
local dstPath = config.pathToSDL .. "smartDeviceLink.ini.origin"


----------------------------------------------------------------------------
-- User functions
function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
    :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end


local n = 1
local function ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, JsonFileName, SystemRequestResultCode, UpdateAppListParams )
  local successValue

  local FileFolder
  local FileName

  FileFolder, FileName = JsonFileName:match("([^/]+)/([^/]+)")

  --mobile side: OnSystemRequest notification 
  EXPECT_NOTIFICATION("OnSystemRequest")
    :Do(function(_,data)
      if data.payload.requestType == "QUERY_APPS" then
        local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
          {
            requestType = "QUERY_APPS", 
            fileName = FileName
          },
          "files/jsons/" .. tostring(JsonFileName))

          --mobile side: SystemRequest response
          self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = successValue, resultCode = SystemRequestResultCode})
      end
    end)
    :ValidIf(function(_,data)
      if data.payload.requestType == "QUERY_APPS" then
        return true
      elseif data.payload.requestType == "LOCK_SCREEN_ICON_URL" then
        return true
      else
        commonFunctions:userPrint(31, " Unexpected requestType value in OnSystemRequest notification is came " .. data.payload.requestType .. ", expected value 'QUERY_APPS' or 'LOCK_SCREEN_ICON_URL'")
        return false
      end
    end)
    :Times(Between(1,2))


  --hmi side: BasicCommunication.UpdateAppList
  EXPECT_HMICALL("BasicCommunication.UpdateAppList", 
    UpdateAppListParams)
    :ValidIf(function(exp,data)
        if
          data.params and
          data.params.applications and
          #data.params.applications == #UpdateAppListParams.applications then
            return true
        else 
          print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected " .. tostring(#UpdateAppListParams.applications) .. " \27[0m")
          return false
        end
    end)
    :Do(function(data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end
----------------------------------------------------------------------------
-- set value of EnableProtocol4 to "true" in smartDeviceLink.ini file
local function SetEnableProtocol4toTrue()
  -- read current content
  local ini_file = io.open(srcPath, "r")
  -- read content 
  local content = ini_file:read("*a")
  ini_file:close()

  -- substitute pattern with "true"
  local res = string.gsub(content, "EnableProtocol4%s-=%s-false", "EnableProtocol4 = true")

    if res then
      -- now save data with correct value
      ini_file = io.open(srcPath, "w+")
      -- write result into dstfile 
      ini_file:write(res)
      ini_file:close()
    end

  -- check if set successfuly
  local check = string.find(res, "EnableProtocol4%s-=%s-true")
  if ( check ~= nil) then 
    print ("value of EnableProtocol4 = true")
    return true
  else
    print ("incorrect value of EnableProtocol4")
  return false
  end

end
--------------------------------------------------------------------------
--make reserve copy of smartDeviceLink.ini file
commonPreconditions:BackupFile("smartDeviceLink.ini")
print ("Backuping smartDeviceLink.ini")

-- set value of "EnableProtocol4" in smartDeviceLink.ini to "true"
SetEnableProtocol4toTrue()

--===================================================================================--
-- Check that SDL write correctly the strings with character's size more than one byte from  language struct to the "vrSynonyms", "ttsName", appName params and send  via UpdateAppList
--===================================================================================--

local LanguagesValue = {"AR-SA", "FR-FR", "DE-DE", "JA-JP", "KO-KR", "RU-RU", "ES-MX"}
local LanguagesNames = {"Arabic", "French", "German", "Japanese", "Korean", "Russian", "Spanish"}

local vrSynonymsttsNamesappNameValuesFirstApp = 
{          
  AR_SA = {
      -- string with 20 characters, totaling 38 bytes
      name = "موسيقى الراب التطبيق",
      -- string with 59 characters, totaling 110 bytes
      ttsName = "الراب والموسيقى التطبيق تحويل النص إلى كلام الاسم الافتراضي",
      -- string with 32 characters, totaling 59 bytes
      vrSynonyms = {
        "موسيقى الراب التطبيق 1 الافتراضي",
        "موسيقى الراب التطبيق 2 الافتراضي"
      }
   },
  FR_FR = {
      -- string with 32 characters, totaling 36 bytes
      name = "Rap Application icôneFrançaiseÂâ",
      -- string with 20 characters, totaling 24 bytes
      ttsName = "icôneFrançaiseÂâ TTS",
      -- string with 34 characters, totaling 38 bytes
      vrSynonyms = {
        "Rap Application 1 icôneFrançaiseÂâ",
        "Rap Application 2 icôneFrançaiseÂâ"
      }
    },
  DE_DE = {
      -- string with 29 characters, totaling 31 bytes
      name = "Rap Application SchaltflächeÜ",
      -- string with 17 characters, totaling 19 bytes
      ttsName = "SchaltflächeÜ TTS",
      -- string with 31 characters, totaling 33 bytes
      vrSynonyms = {
        "Rap Application 1 SchaltflächeÜ",
        "Rap Application 2 SchaltflächeÜ"
      }
    },
  JA_JP = {
      -- string with 11 characters, totaling 33 bytes
      name = "ラップアプリケーション",
      -- string with 14 characters, totaling 36 bytes
      ttsName = "ラップアプリケーションTTS",
      -- string with 14 characters, totaling 36 bytes
      vrSynonyms = {
        "ラップアプリケーション 1 ",
        "ラップアプリケーション 2 "
      }
    },
  KO_KR = {
      -- string with 9 characters, totaling 23 bytes
      name = "랩 응용 프로그램",
      -- string with 9 characters, totaling 23 bytes
      ttsName = "랩 응용 프로그램",
      -- string with 12 characters, totaling 26 bytes
      vrSynonyms = {
        "랩 응용 프로그램 1 ",
        "랩 응용 프로그램 2 "
      }
    },
  RU_RU = {
      -- string with 22 characters, totaling 43 bytes
      name = "Музыкальное приложение",
      -- string with 22 characters, totaling 43 bytes
      ttsName = "Музыкальное приложение",
      -- string with 25 characters, totaling 46 bytes
      vrSynonyms = {
        "Музыкальное приложение 1 ",
        "Музыкальное приложение 2 "
      }
    },
  ES_MX = {
      -- string with 14 characters, totaling 15 bytes
      name = "Rap Aplicación",
      -- string with 14 characters, totaling 15 bytes
      ttsName = "Rap Aplicación",
      -- string with 32 characters, totaling 33 bytes
      vrSynonyms = {
        "Predeterminado Aplicación Rap 1 ",
        "Predeterminado Aplicación Rap 2 "
      }
    }
}

local vrSynonymsttsNamesappNameValuesSecondApp = 
{          
  AR_SA = {
      -- string with 100 characters, totaling 181 bytes
      name = "لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجج",
      -- string with 500 characters, totaling 914 bytes
      ttsName = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
      -- string with 40 characters, totaling 72 bytes
      vrSynonyms = {
        "لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة1",
        "لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة2"
      }
    },
  FR_FR = {
      -- string with 100 characters, totaling 134 bytes
      name = "l'icôneFrançaiseÂâÊêaisondel'arbrelcdelaforêtÎîÔlaforôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondell",
      -- string with 500 characters, totaling 688 bytes
      ttsName = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
      -- string with 40 characters, totaling 46 bytes
      vrSynonyms = {
        "l'icôneFrançaiseÂâÊêaisondel'arbrelcdel1",
        "l'icôneFrançaiseÂâÊêaisondel'arbrelcdel2"
      }
    },
  DE_DE = {
      -- string with 100 characters, totaling 132 bytes
      name = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄäsymboÜüÖöÄänsymlSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖÖ",
      -- string with 500 characters, totaling 634 bytes
      ttsName = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
      -- string with 40 characters, totaling 50 bytes
      vrSynonyms = {
        "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜü1",
        "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜü2"
      }
    },
  JA_JP = {
      -- string with 100 characters, totaling 300 bytes
      name = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示のタンアイコン言語表示言語表示言語表家語表家示のの示示",
      -- string with 500 characters, totaling 1,500 bytes
      ttsName = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
      -- string with 40 characters, totaling 118 bytes
      vrSynonyms = {
        "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語1",
        "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語2"
      }
    },
  KO_KR = {
      -- string with 100 characters, totaling 300 bytes
      name = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운마운트운트버튼아이콘트리하우스의숲호수마언어표시트리하우스의숲호수수",
      -- string with 500 characters, totaling 1,500 bytes
      ttsName = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
      -- string with 40 characters, totaling 118 bytes
      vrSynonyms = {
        "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘1",
        "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘2"
      }
    },
  RU_RU = {
      -- string with 100 characters, totaling 200 bytes
      name = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССС",
      -- string with 500 characters, totaling 1,000 bytes
      ttsName = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
      -- string with 40 characters, totaling 79 bytes
      vrSynonyms = {
        "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУ1",
        "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУ2"
      }
    },
  ES_MX = {
      -- string with 100 characters, totaling 112 bytes
      name = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficiaa",
      -- string with 500 characters, totaling 566 bytes
      ttsName = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
      -- string with 40 characters, totaling 46 bytes
      vrSynonyms = {
        "ElidpañoibéricopañaHamérioEspañEloibéri1",
        "ElidpañoibéricopañaHamérioEspañEloibéri2"
      }
    }
}

for i=1, #LanguagesValue do
--for i=1, 2 do

  --Precondition: Change TTS, VR language
  Test["Precondition_ChangeVRTTSLanguageOnHMI_" .. tostring(LanguagesValue[i])] = function(self)

    self.hmiConnection:SendNotification("TTS.OnLanguageChange",{language = LanguagesValue[i]})
    self.hmiConnection:SendNotification("VR.OnLanguageChange",{language = LanguagesValue[i]})
    self.hmiConnection:SendNotification("UI.OnLanguageChange",{language = LanguagesValue[i]})

    EXPECT_NOTIFICATION("OnLanguageChange", {language = LanguagesValue[i], hmiDisplayLanguage = LanguagesValue[i]})

    if 
      LanguagesValue[i] == "EN-US" then

        local CorIdUnregisterAppInterface = self.mobileSession:SendRPC("UnregisterAppInterface",{})
        --response on mobile side
        EXPECT_RESPONSE(CorIdUnregisterAppInterface, { success = true, resultCode = "SUCCESS"})

    else
      EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})
    end

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})

    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)


    DelayedExp(1000)
  end 

  --===================================================================================--

  --Precondition: Registration of application
  Test["TtNameVrSynonymsappName_" .. tostring(LanguagesValue[i])] = function(self)
    local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", 
      {
          syncMsgVersion =
          {
            majorVersion = 4,
            minorVersion = 2
          },
          appName = "Test Application",
          isMediaApplication = true,
          languageDesired = LanguagesValue[i],
          hmiDisplayLanguageDesired = LanguagesValue[i],
          appHMIType = { "NAVIGATION" },
          appID = "8675308",
          deviceInfo =
          {
            os = "Android",
            carrier = "Megafon",
            firmwareRev = "Name: Linux, Version: 3.4.0-perf",
            osVersion = "4.4.2",
            maxNumberRFCOMMPorts = 1
          }
        })

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
      {
        application = 
          {
            appName = "Test Application"
          }
      })
    :Do(function(_,data)
      self.applications["Test Application"] = data.params.application.appID
      self.appID = data.params.application.appID
    end)

    self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})

    self.mobileSession:ExpectNotification("OnHMIStatus", 
        { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
        :Do(function()
            self.mobileSession.correlationId = self.mobileSession.correlationId + 1
              local msg = 
                {
                  serviceType      = 7,
                  frameInfo        = 0,
                  rpcType          = 2,
                  rpcFunctionId    = 32768,
                  rpcCorrelationId = self.mobileSession.correlationId,
                  payload          = '{"hmiLevel" :"FULL", "audioStreamingState" : "AUDIBLE", "systemContext" : "MAIN"}'
                }

              self.mobileSession:Send(msg)
        end)

    local LangValue = string.gsub (LanguagesValue[i], "-", "_")

    local UpdateAppListParameters = 
      {
        applications = {
           {
              appName = "Test Application",
              appType = { "NAVIGATION" },
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },
              hmiDisplayLanguageDesired = LanguagesValue[i],
              isMediaApplication = true
           },
           {
              appName = vrSynonymsttsNamesappNameValuesFirstApp[LangValue].name,
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },
              greyOut = false,
              ttsName = {
                {
                  type = "TEXT",
                  text = vrSynonymsttsNamesappNameValuesFirstApp[LangValue].ttsName
                }
              },
              vrSynonyms = vrSynonymsttsNamesappNameValuesFirstApp[LangValue].vrSynonyms
           },
           {
              appName = vrSynonymsttsNamesappNameValuesSecondApp[LangValue].name,
              deviceInfo = {
                id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                isSDLAllowed = true,
                name = "127.0.0.1",
                transportType = "WIFI"
              },
              greyOut = false,
              ttsName = {
                {
                  type = "TEXT",
                  text = vrSynonymsttsNamesappNameValuesSecondApp[LangValue].ttsName
                }
              },
              vrSynonyms = vrSynonymsttsNamesappNameValuesSecondApp[LangValue].vrSynonyms
           }    
        }
      }

      local fileName = "JSONWithdifferentLanguagesForApp_utf-8_" .. tostring(LanguagesNames[i]) .. ".json"
      ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "utf-8/" .. tostring(fileName), "SUCCESS", UpdateAppListParameters)
  end

end

function Test:RestoreINIFile()
  print ("restoring smartDeviceLink.ini")
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

