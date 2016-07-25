
--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
-- Set 4 protocol as default for script
config.defaultProtocolVersion = 4

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_language_parameter.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect_OpenConnection("connecttest_language_parameter.lua")

Test = require('user_modules/connecttest_language_parameter')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

-- Set EnableProtocol4 to true
commonFunctions:SetValuesInIniFile("EnableProtocol4%s-=%s-[%w]-%s-\n", "EnableProtocol4", "true" )

local function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
    :Timeout(time + 1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end


local function RegistrationApp(self)
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", 
    {
        syncMsgVersion =
        {
          majorVersion = 4,
          minorVersion = 2
        },
        appName = config.application1.registerAppInterfaceParams.appName,
        isMediaApplication = true,
        languageDesired = 'EN-US',
        hmiDisplayLanguageDesired = 'EN-US',
        appHMIType = config.application1.registerAppInterfaceParams.appHMIType,
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
          appName = config.application1.registerAppInterfaceParams.appName
        }
    })
  :Do(function(_,data)
    self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
    self.appID = data.params.application.appID
  end)

  self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})

  self.mobileSession:ExpectNotification("OnHMIStatus", 
                        { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})


  DelayedExp(1000)

end

local function UnregisterApp(self)
  --request from mobile side
  local CorIdUnregisterAppInterface = self.mobileSession:SendRPC("UnregisterAppInterface",{})

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})

  --response on mobile side
  EXPECT_RESPONSE(CorIdUnregisterAppInterface, { success = true, resultCode = "SUCCESS"})
    :Timeout(2000)

  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

end

local n = 1
local function ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, JsonFileName, SystemRequestResultCode, UpdateAppListParams )
  -- local UpdateAppListTimes
  local successValue

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

  local FileFolder
  local FileName

  FileFolder, FileName = JsonFileName:match("([^/]+)/([^/]+)")

  --mobile side: OnSystemRequest notification 
  EXPECT_NOTIFICATION("OnSystemRequest")
    :Do(function()
        local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
          {
            requestType = "QUERY_APPS", 
            fileName = FileName
          },
          "files/jsons/" .. tostring(JsonFileName))

          --mobile side: SystemRequest response
          self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = successValue, resultCode = SystemRequestResultCode})
      end)

  --------------------------------------------
  --TODO: remove after resolving APPLINK-16052
  for i=1,#UpdateAppListParams.applications do
    if UpdateAppListParams.applications[i].deviceInfo then
      UpdateAppListParams.applications[i].deviceInfo = nil
    end
  end
  --------------------------------------------

  --------------------------------------------
    --TODO: remove after resolving APPLINK-18305
    for i=1,#UpdateAppListParams.applications do
      if 
        UpdateAppListParams.applications[i].ttsName then
          UpdateAppListParams.applications[i].ttsName = UpdateAppListParams.applications[i].ttsName[1].text 
      end
    end
  --------------------------------------------

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

userPrint(33, " Commented SDL defect APPLINK-18305 ")

---------------------------------------------------------------------------------------
--===================================================================================--
-- Check that SDL write a value of "name" to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "language" scruct is omitted
--===================================================================================--

  --Precondition: open session
    function Test:Precondition_OpenSession()
      self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection)

      self.mobileSession.version = 4

      self.mobileSession:StartService(7)
    end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithOmittedLanguageStruct()
    RegistrationApp(self)
  end

  --===================================================================================--

  --language struct is ommited in JSON file
  function Test:JSONWithOmittedLanguageStruct()

    local UpdateAppListParameters = 
        {
          applications = {
             {
                appName = config.application1.registerAppInterfaceParams.appName,
                appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
                isMediaApplication = true
             },
             {
                appName = "Classic Music App",
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
                    text = "Classic Music App"
                  }
                },
                vrSynonyms = {"Classic Music App"}
             },
             {
                appName = "Rap Music App",
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
                    text = "Rap Music App"
                  }
                },
                vrSynonyms = {"Rap Music App"}
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithOmittedLanguageStruct.json", "SUCCESS", UpdateAppListParameters)

  end


--===================================================================================--
-- Check that SDL write a value of "name" to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "language" struct is empty
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithEmptyLanguageStruct()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithEmptyLanguageStruct()
    RegistrationApp(self)
  end

  --===================================================================================--

  --language struct is empty in JSON file
  function Test:JSONWithEmptyLanguageStruct()

    local UpdateAppListParameters = 
        {
          applications = {
             {
                appName = config.application1.registerAppInterfaceParams.appName,
                appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
                hmiDisplayLanguageDesired = "EN-US",
                isMediaApplication = true
             },
             {
                appName = "Rap Music App",
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
                    text = "Rap Music App"
                  }
                },
                vrSynonyms = {"Rap Music App"}
             },
              {
                appName = "Rock music App",
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
                    text = "Rock music App"
                  }
                },
                vrSynonyms = {"Rock music App"}
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithEmptyLanguageStruct.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a value of "name" to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "language" scruct has empty element
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithEmptyElementLanguageStruct()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithEmptyElementLanguageStruct()
    RegistrationApp(self)
  end

  --===================================================================================--

  --language struct has empty element in JSON file
  function Test:JSONWithEmptyElementLanguageStruct()

    local UpdateAppListParameters = 
        {
          applications = {
             {
                appName = config.application1.registerAppInterfaceParams.appName,
                appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
                hmiDisplayLanguageDesired = "EN-US",
                isMediaApplication = true
             },
             {
                appName = "Rap Music App",
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
                    text = "Rap Music App"
                  }
                },
                vrSynonyms = {"Rap Music App"}
             },
             {
                appName = "Rock music App",
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
                    text = "Rock music App"
                  }
                },
                vrSynonyms = {"Rock music App"}
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithEmptyElementInLanguageStruct.json", "SUCCESS", UpdateAppListParameters)

  end

  --===================================================================================--
-- Check that SDL write a value of "name" to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "language" scruct where ttsName and vrSynonyms params are omitted
--=====================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithOmittedttsNamevrSynonyms()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithOmittedttsNamevrSynonyms()
    RegistrationApp(self)
  end

  --===================================================================================--

  --JSON file contains 2 elements in array, one element lacks all mandatory parameters
  function Test:JSONWithOmittedttsNamevrSynonyms()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Crappy Music App",
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
                  text = "Crappy Music App"
                }
              },
              vrSynonyms = {"Crappy Music App"}
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithOmmitedttsNamevrSynonymsLanguageStruct.json", "SUCCESS", UpdateAppListParameters)

  end


--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "language" scruct has only element with current language and without "default" parameter
--===================================================================================--

  ---Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithcurrentHMIlanElementWithoutDefault()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithcurrentHMIlanElementWithoutDefault()
    RegistrationApp(self)
  end

  --===================================================================================--

  --language struct has language element with current HMI language and without "default" parameter
  function Test:JSONWithcurrentHMIlanElementWithoutDefault()

    local UpdateAppListParameters = 
        {
          applications = {
             {
                appName = config.application1.registerAppInterfaceParams.appName,
                appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
                isMediaApplication = true
             }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithcurrentHMIlanElementWithoutDefault.json", "INVALID_DATA", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "language" scruct has only element with current language and "default" parameter
--===================================================================================--

  -- Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithcurrentHMIlanElementWithDefault()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithcurrentHMIlanElementWithDefault()
    RegistrationApp(self)
  end

  --===================================================================================--

  --language struct has language element with current HMI language and with "default" parameter
  function Test:JSONWithcurrentHMIlanElementWithDefault()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Rap music App",
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
                  text = "Rap music App tts name EN"
                }
              },
              vrSynonyms = {"Rap music App 1 EN", "Rap music App 2 EN"}
           },
           {
              appName = "Rock music App",
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
                  text = "Rock music App tts name EN"
                }
              },
              vrSynonyms = {"Rock music App 1 EN", "Rock music App 2 EN"}
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultCurrentDe.json", "SUCCESS", UpdateAppListParameters)

  end


--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "language" scruct has only element with not current language and with "default" parameter
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithNotcurrentHMIlanElementWithDefault()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithNotcurrentHMIlanElementWithDefault()
    RegistrationApp(self)
  end

  --===================================================================================--

  --language struct has no language element with current HMI language and has "default" parameter
  function Test:JSONWithNotcurrentHMIlanElementWithDefault()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Rap music App",
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
                  text = "Rap music App tts name default"
                }
              },
              vrSynonyms = {"Rap music App 1 default", "Rap music App 2 default"}
           },
           {
              appName = "Rock music App",
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
                  text = "Rock music App tts name default"
                }
              },
              vrSynonyms = {"Rock music App 1 default", "Rock music App 2 default"}
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultNotCurrent.json", "SUCCESS", UpdateAppListParameters)

  end
  

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "language" scruct has ttsName in default element and vrSynonyms in current HMI language and vice versa
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithTtsNameVrSynonymsInSeparatedStructs()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithTtsNameVrSynonymsInSeparatedStructs()
    RegistrationApp(self)
  end

  --===================================================================================--

  --language struct has ttsName and vrSynonyms parameters in separated scructs
  function Test:JSONWithTtsNameVrSynonymsInSeparatedStructs()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Rap music App",
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
                  text = "Rap music App"
                }
              },
              vrSynonyms = {"Rap music App 1 EN", "Rap music App 2 EN"}
           },
           {
              appName = "Rock music App",
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
                  text = "Rock music App tts name EN"
                }
              },
              vrSynonyms = {"Rock music App"}
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithTtsNameVrSynonymsInSeparatedStructs.json", "SUCCESS", UpdateAppListParameters)

  end
  

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" param and send  via UpdateAppList to HMI in case "language" scruct has only ttsName, vrSynonym = name
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithTtsName()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithTtsName()
    RegistrationApp(self)
  end

  --===================================================================================--

  --language struct has only ttsName parameters, vrSynonyms is defined by "name" value 
  function Test:JSONWithTtsName()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Rap music App",
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
                  text = "Rap music App tts name default"
                }
              },
              vrSynonyms = {"Rap music App"}
           },
           {
              appName = "Rock music App",
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
                  text = "Rock music App tts name default"
                }
              },
              vrSynonyms = {"Rock music App"}
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithTtsName.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "vrSynonyms" param and send  via UpdateAppList to HMI in case "language" scruct has only vrSynonyms, ttsName = name
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithVrSynonyms()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithVrSynonyms()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has only vrSynonyms parameters, ttsName is defined by "name" value 
  function Test:JSONWithVrSynonyms()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Rap music App",
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
                  text = "Rap music App"
                }
              },
              vrSynonyms = {"Rap music App 1 default", "Rap music App 2 default"}
           },
           {
              appName = "Rock music App",
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
                  text = "Rock music App"
                }
              },
              vrSynonyms = {"Rock music App 1 default", "Rock music App 2 default"}
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithVrSynonyms.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from RegisterAppInterface to the vrSynonyms and ttsName params and send via UpdateAppList to HMI in case "language" scruct has values for ttsName and vrSynonyms
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithOmitedVrSynonymsttsNameForRegisteredApp()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithOmitedVrSynonymsttsNameForRegisteredApp()
    local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", 
                  {
                      syncMsgVersion =
                      {
                        majorVersion = 4,
                        minorVersion = 2
                      },
                      appName = "Test Application",
                      isMediaApplication = true,
                      languageDesired = 'EN-US',
                      hmiDisplayLanguageDesired = 'EN-US',
                      appHMIType = config.application1.registerAppInterfaceParams.appHMIType,
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
                    appName = config.application1.registerAppInterfaceParams.appName
                  }
                })
                :Do(function(_,data)
                  local appId = data.params.application.appID
                  self.appId = appId
                end)

              self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})

              self.mobileSession:ExpectNotification("OnHMIStatus", 
                                      { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  end

  --===================================================================================--
  --language struct has values for vrSynonyms, ttsName for registered app
  function Test:JSONWithOmitedVrSynonymsttsNameForRegisteredApp()

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

    --mobile side: OnSystemRequest notification 
    EXPECT_NOTIFICATION("OnSystemRequest")
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            {
              requestType = "QUERY_APPS", 
              fileName = "JSONWithVrSynonymsttsNameForRegisteredApp"
            },
            "files/jsons/JSON_Language_parameter/JSONWithVrSynonymsttsNameForRegisteredApp.json")

            --mobile side: SystemRequest response
            self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = successValue, resultCode = SystemRequestResultCode})
        end)

  --hmi side: BasicCommunication.UpdateAppList
  EXPECT_HMICALL("BasicCommunication.UpdateAppList", 
    {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
            --[[TODO: uncomment after resolving APPLINK-16052
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },]]
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           }
          }
        })
    :ValidIf(function(exp,data)
        if
          data.params and
          data.params.applications then
            local ReturnValue = true
            local ErrorMessage = ""
            if  #data.params.applications ~= 1 then
              ReturnValue = false
              ErrorMessage = ErrorMessage .. " \27[31m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1 \27[0m"
            end
            if data.params.applications[1].ttsName then
              ReturnValue = false
              ErrorMessage = ErrorMessage .."\n \27[31m BasicCommunication.UpdateAppList contains ttsName value for registered application \27[0m"
            end
            if data.params.applications[1].vrSynonyms then
              ReturnValue = false
              ErrorMessage = ErrorMessage .."\n \27[31m BasicCommunication.UpdateAppList contains vrSynonyms value for registered application \27[0m"
            end

            if ReturnValue == false then
              print(ErrorMessage)
              return false
            else
              return true
            end

        else 
          print(" \27[36m BasicCommunication.UpdateAppList does not contain applications \27[0m")
          return false
        end
    end)
    :Do(function(data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  end

--===================================================================================--
-- Check that SDL write a values from RegisterAppInterface to the vrSynonyms and ttsName params and send via UpdateAppList to HMI in case "language" scruct has different values for ttsName and vrSynonyms
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithVrSynonymsttsNameForRegisteredApp()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithVrSynonymsttsNameForRegisteredApp()
    local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", 
                  {
                      syncMsgVersion =
                      {
                        majorVersion = 4,
                        minorVersion = 2
                      },
                      appName = config.application1.registerAppInterfaceParams.appName,
                      isMediaApplication = true,
                      languageDesired = 'EN-US',
                      hmiDisplayLanguageDesired = 'EN-US',
                      appHMIType = config.application1.registerAppInterfaceParams.appHMIType,
                      appID = "8675308",
                      ttsName = {{text = "Test Application chunk 1", type = "TEXT"},{text = "Test Application chunk 2", type = "TEXT"}},
                      vrSynonyms = {"Test Application vrSynonym"},
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
                    appName = config.application1.registerAppInterfaceParams.appName
                  }
                })
                :Do(function(_,data)
                  local appId = data.params.application.appID
                  self.appId = appId
                end)

              self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})

              self.mobileSession:ExpectNotification("OnHMIStatus", 
                                      { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  end

  --===================================================================================--
  --language struct has values for vrSynonyms, ttsName for registered app
  function Test:JSONWithVrSynonymsttsNameForRegisteredApp()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true,
              ttsName = {
                {
                  type = "TEXT",
                  text = "Test Application chunk 1"
                },
                {
                  type = "TEXT",
                  text = "Test Application chunk 2"
                }
              },
              vrSynonyms = {"Test Application vrSynonym"}
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithVrSynonymsttsNameForRegisteredApp.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from  language struct to the "vrSynonyms", "ttsName" param for current HMI language and send  via UpdateAppList
--===================================================================================--

local LanguagesValue = {"ES-MX", "FR-CA", "DE-DE", "ES-ES", "EN-GB", "RU-RU", "TR-TR", "PL-PL", "FR-FR", "IT-IT", "SV-SE", "PT-PT", "NL-NL", "EN-AU", "ZH-CN", "ZH-TW", "JA-JP", "AR-SA", "KO-KR", "PT-BR", "CS-CZ", "DA-DK", "NO-NO", "NL-BE", "EL-GR", "HU-HU", "FI-FI", "SK-SK", "EN-US",} 

local vrSynonymsttsNamesValuesRapApp = 
{          
  EN_US = {
      ttsName = "Rap music App tts name US",
      vrSynonyms = {
        "Rap music App 1 US",
        "Rap music App 2 US"
      }
   },
  ES_MX = {
      ttsName = "La música rap App",
      vrSynonyms = {
        "La música rap App 1",
        "La música rap App 2"
      }
    },
  FR_CA = {
      ttsName = "Application de musique de coup sec",
      vrSynonyms = {
        "Application de musique de coup sec 1",
        "Application de musique de coup sec 2"
      }
    },
  DE_DE = {
      ttsName = "Rap-Musik App",
      vrSynonyms = {
        "Rap-Musik App 1",
        "Rap-Musik App 2"
      }
    },
  ES_ES = {
      ttsName = "La música rap App",
      vrSynonyms = {
        "La música rap App 1",
        "La música rap App 2"
      }
    },
  EN_GB = {
      ttsName = "Rap music App tts name GB",
      vrSynonyms = {
        "Rap music App 1 GB",
        "Rap music App 2 GB"
      }
    },
  RU_RU = {
      ttsName = "Музыкальное приложение",
      vrSynonyms = {
        "Приложение 1",
        "Приложение 2"
      }
    },
  TR_TR = {
      ttsName = "Rap müzik App",
      vrSynonyms = {
        "Rap müzik App 1",
        "Rap müzik App 2"
      }
    },
  PL_PL = {
      ttsName = "Muzyki rap aplikacji",
      vrSynonyms = {
        "Muzyki rap aplikacji 1",
        "Muzyki rap aplikacji 2"
      }
    },
  FR_FR = {
      ttsName = "Musique rap application de",
      vrSynonyms = {
        "Musique rap application de 1",
        "Musique rap application de 2"
      }
    },
  IT_IT = {
      ttsName = "Musica di colpo secco applicazione",
      vrSynonyms = {
        "Musica di colpo secco applicazione 1",
        "Musica di colpo secco applicazione 2"
      }
    },
  SV_SE = {
      ttsName = "Rappar musik appen",
      vrSynonyms = {
        "Rappar musik appen 1",
        "Rappar musik appen 2"
      }
    },
  PT_PT = {
      ttsName = "Música Rap App PT",
      vrSynonyms = {
        "Música Rap App 1 PT",
        "Música Rap App 2 PT"
      }
    },
  NL_NL = {
      ttsName = "Rapmuziek Applicatiegebruikers NL",
      vrSynonyms = {
        "Rapmuziek Applicatiegebruikers 1 NL",
        "Rapmuziek Applicatiegebruikers 2 NL"
      }
    },
  EN_AU = {
      ttsName = "Rap music App tts name AU",
      vrSynonyms = {
        "Rap music App 1 AU",
        "Rap music App 2 AU"
      }
    },
  ZH_CN = {
      ttsName = "說唱音樂應用程序",
      vrSynonyms = {
        "說唱音樂應用程序 1",
        "說唱音樂應用程序 2"
      }
    },
  ZH_TW = {
      ttsName = "说唱音乐应用程序",
      vrSynonyms = {
        "说唱音乐应用程序 1",
        "说唱音乐应用程序 2"
      }
    },
  JA_JP = {
      ttsName = "ラップミュージックアプリ",
      vrSynonyms = {
        "ラップミュージックアプリ 1",
        "ラップミュージックアプリ 2"
      }
    },
  AR_SA = {
      ttsName = "موسيقى الراب التطبيق",
      vrSynonyms = {
        "موسيقى الراب التطبيق 1",
        "موسيقى الراب التطبيق 2"
      }
    },
  KO_KR = {
      ttsName = "랩 음악 앱",
      vrSynonyms = {
        "랩 음악 앱 1",
        "랩 음악 앱 2"
      }
    },
  PT_BR = {
      ttsName = "Música Rap App BR",
      vrSynonyms = {
        "Música Rap App 1 BR",
        "Música Rap App 2 BR"
      }
    },
  CS_CZ = {
      ttsName = "Rapové hudby aplikace",
      vrSynonyms = {
        "Rapové hudby aplikace 1",
        "Rapové hudby aplikace 2"
      }
    },
  DA_DK = {
      ttsName = "Rap-musik App",
      vrSynonyms = {
        "Rap-musik App 1",
        "Rap-musik App 2"
      }
    },
  NO_NO = {
      ttsName = "Rap musikk App",
      vrSynonyms = {
        "Rap musikk App 1",
        "Rap musikk App 2"
      }
    },
  NL_BE = {
      ttsName = "Rapmuziek Applicatiegebruikers BE",
      vrSynonyms = {
        "Rapmuziek Applicatiegebruikers 1 BE",
        "Rapmuziek Applicatiegebruikers 2 BE"
      }
    },
  EL_GR = {
      ttsName = "Κτυπήματος μουσικής εφαρμογή",
      vrSynonyms = {
        "Κτυπήματος μουσικής 1",
        "Κτυπήματος μουσικής 2"
      }
    },
  HU_HU = {
      ttsName = "Rap zenét App",
      vrSynonyms = {
        "Rap zenét App 1",
        "Rap zenét App 2"
      }
    },
  FI_FI = {
      ttsName = "Rap-musiikkia sovellus",
      vrSynonyms = {
        "Rap-musiikkia sovellus 1",
        "Rap-musiikkia sovellus 2"
      }
    },
  SK_SK = {
      ttsName = "Rap music aplikácia",
      vrSynonyms = {
        "Rap music aplikácia 1",
        "Rap music aplikácia 2"
      }
    }
}

local vrSynonymsttsNamesValuesRockApp = 
{
  EN_US = {
      ttsName = "Rock music App tts name US",
      vrSynonyms = {
        "Rock music App 1 US",
        "Rock music App 2 US"
      }
    },
  ES_MX = {
      ttsName = "La música Rock App",
      vrSynonyms = {
        "La música Rock App 1",
        "La música Rock App 2"
      }
    },
  FR_CA = {
      ttsName = "La musique rock application de",
      vrSynonyms = {
        "La musique rock application de 1",
        "La musique rock application de 2"
      }
    },
  DE_DE = {
      ttsName = "Rock-Musik App",
      vrSynonyms = {
        "Rock-Musik App 1",
        "Rock-Musik App 2"
      }
    },
  ES_ES = {
      ttsName = "La música Rock App",
      vrSynonyms = {
        "La música Rock App 1",
        "La música Rock App 2"
      }
    },
  EN_GB = {
      ttsName = "Rock music App tts name GB",
      vrSynonyms = {
        "Rock music App 1 GB",
        "Rock music App 2 GB"
      }
    },
  RU_RU = {
      ttsName = "Музыкальное рок приложение",
      vrSynonyms = {
        "Рок приложение 1",
        "Рок приложение 2"
      }
    },
  TR_TR = {
      ttsName = "Rock müzik App",
      vrSynonyms = {
        "Rock müzik App 1",
        "Rock müzik App 2"
      }
    },
  PL_PL = {
      ttsName = "Muzyki Rock aplikacji",
      vrSynonyms = {
        "Muzyki Rock aplikacji 1",
        "Muzyki Rock aplikacji 2"
      }
    },
  FR_FR = {
      ttsName = "Musique Rock application de",
      vrSynonyms = {
        "Musique Rock application de 1",
        "Musique Rock application de 2"
      }
    },
  IT_IT = {
      ttsName = "La musica rock applicazione",
      vrSynonyms = {
        "La musica rock applicazione 1",
        "La musica rock applicazione 2"
      }
    },
  SV_SE = {
      ttsName = "Rockar musik appen",
      vrSynonyms = {
        "Rockar musik appen 1",
        "Rockar musik appen 2"
      }
    },
  PT_PT = {
      ttsName = "Música Rock App PT",
      vrSynonyms = {
        "Música Rock App 1 PT",
        "Música Rock App 2 PT"
      }
    },
  NL_NL = {
      ttsName = "Rockmuziek Applicatiegebruikers NL",
      vrSynonyms = {
        "Rockmuziek Applicatiegebruikers 1 NL",
        "Rockmuziek Applicatiegebruikers 2 NL"
      }
    },
  EN_AU = {
      ttsName = "Rock music App tts name AU",
      vrSynonyms = {
        "Rock music App 1 AU",
        "Rock music App 2 AU"
      }
    },
  ZH_CN = {
      ttsName = "搖滾音樂應用",
      vrSynonyms = {
        "搖滾音樂應用 1",
        "搖滾音樂應用 2"
      }
    },
  ZH_TW = {
      ttsName = "摇滚音乐应用",
      vrSynonyms = {
        "摇滚音乐应用 1",
        "摇滚音乐应用 2"
      }
    },
  JA_JP = {
      ttsName = "ロックミュージックアプリ",
      vrSynonyms = {
        "ロックミュージックアプリ 1",
        "ロックミュージックアプリ 2"
      }
    },
  AR_SA = {
      ttsName = "موسيقى الروك التطبيق",
      vrSynonyms = {
        "موسيقى الروك التطبيق 1",
        "موسيقى الروك التطبيق 2"
      }
    },
  KO_KR = {
      ttsName = "록 음악 앱",
      vrSynonyms = {
        "록 음악 앱 1",
        "록 음악 앱 2"
      }
    },
  PT_BR = {
      ttsName = "Música Rock App BR",
      vrSynonyms = {
        "Música Rock App 1 BR",
        "Música Rock App 2 BR"
      }
    },
  CS_CZ = {
      ttsName = "Rockové hudby aplikace",
      vrSynonyms = {
        "Rockové hudby aplikace 1",
        "Rockové hudby aplikace 2"
      }
    },
  DA_DK = {
      ttsName = "Rock-musik App",
      vrSynonyms = {
        "Rock-musik App 1",
        "Rock-musik App 2"
      }
    },
  NO_NO = {
      ttsName = "Rock musikk App",
      vrSynonyms = {
        "Rock musikk App 1",
        "Rock musikk App 2"
      }
    },
  NL_BE = {
      ttsName = "Rockmuziek Applicatiegebruikers BE",
      vrSynonyms = {
        "Rockmuziek Applicatiegebruikers 1 BE",
        "Rockmuziek Applicatiegebruikers 2 BE"
      }
    },
  EL_GR = {
      ttsName = "Βράχο μουσική εφαρμογή",
      vrSynonyms = {
        "Βράχο μουσική 1",
        "Βράχο μουσική 2"
      }
    },
  HU_HU = {
      ttsName = "Rock zenét App",
      vrSynonyms = {
        "Rock zenét App 1",
        "Rock zenét App 2"
      }
    },
  FI_FI = {
      ttsName = "Rock-musiikkia sovellus",
      vrSynonyms = {
        "Rock-musiikkia sovellus 1",
        "Rock-musiikkia sovellus 2"
      }
    },
  SK_SK = {
      ttsName = "Rock music aplikácia",
      vrSynonyms = {
        "Rock music aplikácia 1",
        "Rock music aplikácia 2"
      }
    }
}


for i=1, #LanguagesValue do

  --Precondition: Change TTS, VR language
  Test["ChangeVRTTSLanguageOnHMI_" .. tostring(LanguagesValue[i])] = function(self)

    self.hmiConnection:SendNotification("TTS.OnLanguageChange",{language = LanguagesValue[i]})
    self.hmiConnection:SendNotification("VR.OnLanguageChange",{language = LanguagesValue[i]})

    EXPECT_NOTIFICATION("OnLanguageChange", {language = LanguagesValue[i], hmiDisplayLanguage = "EN-US"})

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


    -- DelayedExp(2000)
  end 

--===================================================================================--

  --Precondition: Registration of application
  Test["Precondition_AppRegistration_ttNameVrSynonymsForCurrentHMILanguage" .. tostring(LanguagesValue[i])] = function(self)
    local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", 
      {
          syncMsgVersion =
          {
            majorVersion = 4,
            minorVersion = 2
          },
          appName = config.application1.registerAppInterfaceParams.appName,
          isMediaApplication = true,
          languageDesired = 'EN-US',
          hmiDisplayLanguageDesired = 'EN-US',
          appHMIType = config.application1.registerAppInterfaceParams.appHMIType,
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
            appName = config.application1.registerAppInterfaceParams.appName
          }
      })
    :Do(function(_,data)
      self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
      self.appID = data.params.application.appID
    end)

    local resultCodeValue
    if 
      LanguagesValue[i] == "EN-US" then
        resultCodeValue = "SUCCESS"
    else 
        resultCodeValue = "WRONG_LANGUAGE"
    end

    self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = resultCodeValue})

    self.mobileSession:ExpectNotification("OnHMIStatus", 
        { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  end

  Test["TtNameVrSynonymsForCurrentHMILanguage_" .. tostring(LanguagesValue[i])] = function(self)

      local LangValue = string.gsub (LanguagesValue[i], "-", "_")

      local UpdateAppListParameters = 
        {
          applications = {
             {
                appName = config.application1.registerAppInterfaceParams.appName,
                appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
                hmiDisplayLanguageDesired = "EN-US",
                isMediaApplication = true
             },
             {
                appName = "Rap music App",
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
                    text = vrSynonymsttsNamesValuesRapApp[LangValue].ttsName
                  }
                },
                vrSynonyms = vrSynonymsttsNamesValuesRapApp[LangValue].vrSynonyms
             },
             {
                appName = "Rock music App",
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
                    text = vrSynonymsttsNamesValuesRockApp[LangValue].ttsName
                  }
                },
                vrSynonyms = vrSynonymsttsNamesValuesRockApp[LangValue].vrSynonyms
             }    
          }
        }

        ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithdifferentLanguagesForApp.json", "SUCCESS", UpdateAppListParameters)
  end

end
    
--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "tts" and "vrSynonym" have lower bound values
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithVrSynonymsttsNameLowerBound()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithVrSynonymsttsNameLowerBound()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has lower bound values for vrSynonyms, ttsName
  function Test:JSONWithVrSynonymsttsNameLowerBound()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Rap music App",
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
                  text = "1"
                }
              },
              vrSynonyms = {"A"}
           },
           {
              appName = "Rock music App",
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
                  text = "B"
                }
              },
              vrSynonyms = {"2"}
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultVrTtsLowerBound.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "tts" and "vrSynonym" have upper bound values
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithVrSynonymsttsNameUpperBound()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithVrSynonymsttsNameUpperBound()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has upper values for vrSynonyms, ttsName 
  function Test:JSONWithVrSynonymsttsNameUpperBound()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           },
           {
              appName = "Rap music App",
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
                  text = "\\bnn\\fddhjhr567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0_1"
                }
              },
              vrSynonyms = {
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_1",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_2",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_3",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_4",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_5",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_6",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_7",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_8",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_1_9",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_10",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_11",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_12",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_13",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_14",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_15",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_16",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_17",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_18",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_19",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_20",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_21",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_22",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_23",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_24",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_25",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_26",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_27",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_28",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_29",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_30",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_31",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_32",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_33",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_34",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_35",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_36",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_37",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_38",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_39",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_40",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_41",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_42",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_43",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_44",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_45",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_46",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_47",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_48",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_49",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_50",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_51",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_52",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_53",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_54",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_55",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_56",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_57",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_58",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_59",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_60",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_61",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_62",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_63",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_64",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_65",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_66",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_67",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_68",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_69",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_70",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_71",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_72",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_73",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_74",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_75",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_76",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_77",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_78",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_79",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_80",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_81",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_82",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_83",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_84",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_85",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_86",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_87",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_88",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_89",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_90",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_91",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_92",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_93",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_94",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_95",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_96",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_97",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_98",
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_1_99",          
                "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^()_1_100"
              }
           },
           {
              appName = "Rock music App",
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
                  text = "\\bnn\\fddhjhr567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0_2"
                }
              },
              vrSynonyms = {
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_1",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_2",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_3",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_4",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_5",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_6",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_7",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_8",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&*()_2_9",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_10",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_11",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_12",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_13",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_14",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_15",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_16",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_17",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_18",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_19",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_20",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_21",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_22",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_23",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_24",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_25",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_26",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_27",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_28",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_29",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_30",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_31",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_32",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_33",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_34",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_35",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_36",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_37",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_38",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_39",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_40",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_41",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_42",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_43",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_44",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_45",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_46",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_47",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_48",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_49",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_50",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_51",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_52",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_53",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_54",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_55",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_56",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_57",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_58",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_59",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_60",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_61",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_62",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_63",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_64",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_65",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_66",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_67",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_68",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_69",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_70",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_71",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_72",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_73",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_74",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_75",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_76",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_77",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_78",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_79",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_80",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_81",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_82",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_83",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_84",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_85",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_86",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_87",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_88",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_89",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_90",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_91",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_92",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_93",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_94",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_95",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_96",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_97",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_98",
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^&()_2_99",          
                  "QWERTYUIOPASDFGhjklzxcvbnm!?#$%^()_2_100"
              }
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultVrTtsUpperBound.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "vrSynonym" have out upper bound element count
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithVrSynonymsOutUpperBoundCount()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithVrSynonymsOutUpperBoundCount()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has out upper bound elemet count for vrSynonyms
  function Test:JSONWithVrSynonymsOutUpperBoundCount()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultVrOutUpperBoundCount.json", "INVALID_DATA", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "vrSynonym" have out lower bound element count
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithVrSynonymsOutLowerBoundCount()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithVrSynonymsOutLowerBoundCount()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has out lower bound elemet count for vrSynonyms
  function Test:JSONWithVrSynonymsOutUpperBoundCount()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultVrOutLowerBoundCount.json", "INVALID_DATA", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "vrSynonym" have out lower bound value
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithVrSynonymsOutLowerBound()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithVrSynonymsOutLowerBound()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has out lower bound value for vrSynonyms
  function Test:JSONWithVrSynonymsOutLowerBound()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultVrOutLowerBound.json", "INVALID_DATA", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "vrSynonym" have out upper bound value
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithVrSynonymsOutUpperBound()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithVrSynonymsOutUpperBound()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has out upper bound value for vrSynonyms  
  function Test:JSONWithVrSynonymsOutUpperBound()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultVrOutUpperBound.json", "INVALID_DATA", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "ttsName" have out lower bound value
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithTtsNameOutLowerBound()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithTtsNameOutLowerBound()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has out lower bound value for vrSynonyms 
  function Test:JSONWithTtsNameOutLowerBound()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultTtsOutLowerBound.json", "INVALID_DATA", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL write a values from language struct to the "tts" and "vrSynonym" params and send them via UpdateAppList to HMI in case "ttsName" have out upper bound value
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithTtsNameOutUpperBound()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithTtsNameOutUpperBound()
    RegistrationApp(self)
  end

  --===================================================================================--
  --language struct has out upper bound value for vrSynonyms  
  function Test:JSONWithTtsNameOutUpperBound()

    local UpdateAppListParameters = 
        {
          applications = {
           {
              appName = config.application1.registerAppInterfaceParams.appName,
              appType = config.application1.registerAppInterfaceParams.appHMIType,
                deviceInfo = {
                  id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                  isSDLAllowed = true,
                  name = "127.0.0.1",
                  transportType = "WIFI"
                },
              hmiDisplayLanguageDesired = "EN-US",
              isMediaApplication = true
           }
          }
        }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Language_parameter/JSONWithLanguageDefaultTtsOutUpperBound.json", "INVALID_DATA", UpdateAppListParameters)

  end

function Test:Postcondition_removeCreatedUserConnecttest()
  os.execute(" rm -f  ./user_modules/connecttest_language_parameter.lua")
end