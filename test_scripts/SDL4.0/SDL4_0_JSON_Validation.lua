
--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
-- Set 4 protocol as default for script
config.defaultProtocolVersion = 4

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_validation_json.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect_OpenConnection("connecttest_validation_json.lua")

Test = require('user_modules/connecttest_validation_json')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

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

local UpdateAppListParamsStartApp
local function RegistrationApp(self)

  local RAIParams = config.application1.registerAppInterfaceParams

  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", 
    RAIParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
    {
      application = 
        {
          appName = RAIParams.appName
        }
    })
  :Do(function(_,data)
    self.applications[RAIParams.appName] = data.params.application.appID
    self.appID = data.params.application.appID
  end)

  UpdateAppListParamsStartApp = 
   {
      appName = RAIParams.appName,
      appType = RAIParams.appHMIType,
    --[=[TODO: remove after resolving APPLINK-16052
      deviceInfo = {
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
        isSDLAllowed = true,
        name = "127.0.0.1",
        transportType = "WIFI"
      },
    ]=]
      hmiDisplayLanguageDesired = RAIParams.hmiDisplayLanguageDesired,
      isMediaApplication = RAIParams.isMediaApplication
   }

  EXPECT_HMICALL("BasicCommunication.UpdateAppList",
    {
      applications = {
       UpdateAppListParamsStartApp
      }
    })
    :ValidIf(function(_,data)
      if
        data.params and
        data.params.applications and
        #data.params.applications == 1 then
          return true
      else 
        print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1 \27[0m")
        return false
      end
    end)
    :Do(function(data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)


  self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})

  self.mobileSession:ExpectNotification("OnHMIStatus", 
                        { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})


  DelayedExp(2000)

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

  DelayedExp(1000)
end

-- Sending OnHMIStatus notification form mobile application
local function SendingOnHMIStatusFromMobile(self, level, audibleState, sessionName )
  
  if level == nil then
    level = "FULL"
  end

  if audibleState == nil then
    audibleState = "NOT_AUDIBLE"
  end

  if sessionName == nil then
    sessionName = self.mobileSession
  end

  sessionName.correlationId = sessionName.correlationId + 1

    local msg = 
        {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 2,
          rpcFunctionId    = 32768,
          rpcCorrelationId = sessionName.correlationId,
          payload          = '{"hmiLevel" :"' .. tostring(level) .. '", "audioStreamingState" : "' .. tostring(audibleState) .. '", "systemContext" : "MAIN"}'
        }

    sessionName:Send(msg)

    if 
      sessionName == self.mobileSession then
          sessionDesc = "first session"
    elseif
      sessionName == self.mobileSession1 then
          sessionDesc = "second session"
    elseif
      sessionName == self.mobileSession2 then
          sessionDesc = "third session"
    elseif
      sessionName == self.mobileSession3 then
          sessionDesc = "fourth session"
    elseif
      sessionName == self.mobileSession4 then
          sessionDesc = "fifth session"
    elseif
      sessionName == self.mobileSession5 then
          sessionDesc = "sixth session"
    elseif
      sessionName == self.mobileSession6 then
          sessionDesc = "sixth session"
    end

    userPrint(33, "Sending OnHMIStatus from mobile app with level ".. tostring(level) .. " in " .. tostring(sessionDesc) )

end

local n = 1
local function ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, JsonFileName, SystemRequestResultCode, UpdateAppListParams )
  local UpdateAppListTimes
  local successValue

  SendingOnHMIStatusFromMobile(self)

  if 
    SystemRequestResultCode == "SUCCESS" then
      UpdateAppListTimes = 1
      successValue = true
  else
      UpdateAppListTimes = 0
      successValue = false
  end

  local FileFolder
  local FileName

  FileFolder, FileName = JsonFileName:match("([^/]+)/([^/]+)")

  --mobile side: OnSystemRequest notification 
  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "QUERY_APPS"})
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

  local ExpectedAppsValue

  if UpdateAppListParams.applications then
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
          UpdateAppListParams.applications[i].ttsName = nil 
      end
    end
    --------------------------------------------
  end


  --hmi side: BasicCommunication.UpdateAppList
  EXPECT_HMICALL("BasicCommunication.UpdateAppList", 
    UpdateAppListParams)
    :ValidIf(function(_,data)
      if
        data.params and
        data.params.applications then
          if #data.params.applications ~= nil  then
            if 
              #data.params.applications == #UpdateAppListParams.applications then
              return true
            else 
              print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected " .. tostring(#UpdateAppListParams.applications) .. " \27[0m")
              return false
            end
          else
            print(" \27[36m Application array is empty \27[0m")
            return false
          end
      else
        print(" \27[36m Application array is absent \27[0m")
        return false
      end
    end)
    :Do(function(data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
    :Times(UpdateAppListTimes)

    DelayedExp(1000)
end

--Check pathToSDL, in case last symbol is not'/' add '/' 
local function checkSDLPathValue()
  findresult = string.find (config.pathToSDL, '.$')

  if string.sub(config.pathToSDL,findresult) ~= "/" then
    config.pathToSDL = config.pathToSDL..tostring("/")
  end 
end

userPrint(33, " Commented SDL defect APPLINK-18305 ")

function Test:Precondition_OpenSession()
  self.mobileSession = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession.version = 4

  self.mobileSession:StartService(7)
end

---------------------------------------------------------------------------------------
--===================================================================================--
-- Check that SDL processes valid JSON file with all mandatory params with 2 apps
--===================================================================================--

  --Precondition: Registration of application 
  function Test:Precondition_AppRegistration_JSONWithAllValidParams()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  --===================================================================================--

  function Test:JSONWithAllValidParams()

    local UpdateAppListParameters = 
      {
        applications = {
         UpdateAppListParamsStartApp,
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
         },
         {
            appName = "Awesome Music App",
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
                text = "Awesome Music App"
              }
            },
            vrSynonyms = {"Awesome Music App"}
         }
        }
      }


    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "QUERRY_jsons/correctJSON.json", "SUCCESS", UpdateAppListParameters)

  end

---------------------------------------------------------------------------------------
--===================================================================================--
-- Check that SDL ignore 'query-apps'-JSON-file's element of the array lacks of "appID"
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutAppIDInArrayElements()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutAppIDInArrayElements()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  --===================================================================================--
  --JSON file contains 4 elements in array, two elements lacks "appID" parameter
  function Test:JSONWithoutAppIDInArrayElements()

      local UpdateAppListParameters = 
        {
          applications = {
           UpdateAppListParamsStartApp,
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

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutAppIDInSomeArrayElements.json", "SUCCESS", UpdateAppListParameters)

  end

---------------------------------------------------------------------------------------
--===================================================================================--
-- Check that SDL ignore 'query-apps'-JSON-file's element of the array lacks of "name"
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutNameInArrayElements()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutNameInArrayElements()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  --===================================================================================--
  --JSON file contains 4 elements in array, 2 elements lack "name" parameter
  function Test:JSONWithoutNameInArrayElements()

    local UpdateAppListParameters = 
        {
          applications = {
           UpdateAppListParamsStartApp,
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

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutNameInSomeArrayElements.json", "SUCCESS", UpdateAppListParameters)

  end

---------------------------------------------------------------------------------------
--===================================================================================--
-- Check that SDL ignore 'query-apps'-JSON-file's element of the array lacks of "packageName"
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutPackageNameInOneArrayElement()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutPackageNameInOneArrayElement()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  --===================================================================================--
  --JSON file contains 4 elements in array, one element lacks "packageName" parameter
  function Test:JSONWithoutPackageNameInOneArrayElement()

    local UpdateAppListParameters = 
        {
          applications = {
           UpdateAppListParamsStartApp,
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

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutPackageNameInOneArrayElement.json", "SUCCESS", UpdateAppListParameters)

  end

---------------------------------------------------------------------------------------
--===================================================================================--
-- Check that SDL ignore 'query-apps'-JSON-file's element of the array lacks of "urlScheme"
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutUrlSchemeInOneArrayElement()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutUrlSchemeInOneArrayElement()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  --===================================================================================--
  --JSON file contains 4 elements in array, one element lacks "urlScheme" parameter
  function Test:JSONWithoutUrlSchemeInOneArrayElement()

    local UpdateAppListParameters = 
        {
          applications = {
           UpdateAppListParamsStartApp,
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
              appName = "Awesome Music App",
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
                  text = "Awesome Music App"
                }
              },
              vrSynonyms = {"Awesome Music App"}
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

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutUrlSchemeInOneArrayElement.json", "SUCCESS", UpdateAppListParameters)

  end

---------------------------------------------------------------------------------------
--===================================================================================--
-- Check that SDL ignore 'query-apps'-JSON-file's element of the array lacks of "appID", "name", "packageName"
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutAndroidMandatoryParametersInOneArrayElement()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutAndroidMandatoryParametersInOneArrayElement()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  -- --===================================================================================--
  --JSON file contains 4 elements in array, one element lacks all android mandatory parameters
  function Test:JSONWithoutAndroidMandatoryParametersInOneArrayElement()

    local UpdateAppListParameters = 
        {
          applications = {
             UpdateAppListParamsStartApp,
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

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutAndroidMandatoryParametersInOneArrayElement.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL ignore 'query-apps'-JSON-file's element of the array lacks of "appID", "name", "urlScheme"
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutIosMandatoryParametersInOneArrayElement()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutIosMandatoryParametersInOneArrayElement()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  --===================================================================================--
  --JSON file contains 4 elements in array, one element lacks all mandatory parameters
  function Test:JSONWithoutIosMandatoryParametersInOneArrayElement()

    local UpdateAppListParameters = 
        {
          applications = {
           UpdateAppListParamsStartApp,
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
              appName = "Awesome Music App",
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
                  text = "Awesome Music App"
                }
              },
              vrSynonyms = {"Awesome Music App"}
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

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutIosMandatoryParametersInOneArrayElement.json", "SUCCESS", UpdateAppListParameters)

  end
--===================================================================================--
-- Check that SDL ignore empty 'query-apps'-JSON-file's element of the array
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutParametesInOneArrayElement()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutParametesInOneArrayElement()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  --===================================================================================--
  --JSON file contains 2 elements in array, one element lacks all mandatory parameters
  function Test:JSONWithoutParametesInOneArrayElement()
 
    local UpdateAppListParameters = 
        {
          applications = {
           UpdateAppListParamsStartApp,
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

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutParametersInOneArrayElement.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL process 'query-apps'-JSON-file's element with only mandatory params "appID", "name", "packageName", "urlScheme"
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithOnlyMandatoryInArrayElements()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithOnlyMandatoryInArrayElements()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  -- --===================================================================================--
  --JSON contains 2 elements in array, elements contain only mandatory parameters "appID", "name", "packageName", "urlScheme"
  function Test:JSONWithOnlyMandatoryInArrayElements()

    local UpdateAppListParameters = 
      {
        applications = {
         UpdateAppListParamsStartApp,
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
         },
         {
            appName = "Awesome Music App",
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
                text = "Awesome Music App"
              }
            },
            vrSynonyms = {"Awesome Music App"}
         }
        }
      }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithOnlyMandatoryInArrayElements.json", "SUCCESS", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL consider the JSON file as invalid in case elements of array does not contains: "appID" parameter
--===================================================================================--

  --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutAppID()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutAppID()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

  --===================================================================================--
  --JSON contains only elements without appID parameter
  function Test:JSONWithoutAppID()

    local UpdateAppListParameters = 
      {
        applications = {
          UpdateAppListParamsStartApp
        }
      }

    ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutAppID.json", "INVALID_DATA", UpdateAppListParameters)

  end

--===================================================================================--
-- Check that SDL consider the JSON file as invalid in case elements of array does not contains "name" parameter
--===================================================================================--

    --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutName()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutName()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

    --===================================================================================--
    --JSON contains only elements without "name" parameter
    function Test:JSONWithoutName()

      local UpdateAppListParameters = 
      {
        applications = {
          UpdateAppListParamsStartApp
        }
      }

      ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutName.json", "INVALID_DATA", UpdateAppListParameters)

    end

--===================================================================================--
-- Check that SDL consider the JSON file as invalid in case elements of array does not contains "packageName" parameter
--===================================================================================--

    --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutPackageName()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutPackageName()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

    --===================================================================================--
    --JSON contains one element without packageName parameter
    function Test:JSONWithoutPackageName()

      local UpdateAppListParameters = 
      {
        applications = {
          UpdateAppListParamsStartApp
        }
      }

      ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutPackageName.json", "INVALID_DATA", UpdateAppListParameters)

    end



--===================================================================================--
-- Check that SDL consider the JSON file as invalid in case elements of array does not contains "urlScheme" parameter
--===================================================================================--

    --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutUrlScheme()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutUrlScheme()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

    --===================================================================================--
    --JSON contains one element without urlScheme parameter
    function Test:JSONWithoutUrlScheme()

      local UpdateAppListParameters = 
      {
        applications = {
          UpdateAppListParamsStartApp
        }
      }

      ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutUrlScheme.json", "INVALID_DATA", UpdateAppListParameters)

    end

--===================================================================================--
-- Check that SDL consider the JSON file as invalid in case elements of array does not contains one of parameters: "appID", "name", "packageName", "urlScheme"

    --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithoutAppIDNamePackageNameUrlScheme()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithoutAppIDNamePackageNameUrlScheme()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

    --===================================================================================--
    --JSON contains empty response array
    function Test:JSONWithoutAppIDNamePackageNameUrlScheme()

      local UpdateAppListParameters = 
      {
        applications = {
          UpdateAppListParamsStartApp
        }
      }

      ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithoutUrlSchemeInpackageNameNameAppId.json", "INVALID_DATA", UpdateAppListParameters)

    end

--===================================================================================--
-- Check that SDL consider the JSON file as invalid in case empty response array in JSON file
--===================================================================================--

    --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithEmptyResponseArray()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithEmptyResponseArray()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

    --===================================================================================--
    --JSON contains empty response array
    function Test:JSONWithEmptyResponseArray()

      local UpdateAppListParameters = 
      {
        applications = {
          UpdateAppListParamsStartApp
        }
      }

      ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONEmptyResponseArray.json", "INVALID_DATA", UpdateAppListParameters)

    end

--===================================================================================--
-- Check that SDL consider the JSON file as invalid in case JSON file has invalid syntax
--===================================================================================--

    --Precondition: unregistration of app
  function Test:Precondition_UnregisterAppInterface_JSONWithInvalidSyntax()
    UnregisterApp(self)
  end

  --===================================================================================--

  --Precondition: Registration of application
  function Test:Precondition_AppRegistration_JSONWithInvalidSyntax()
    RegistrationApp(self)

    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL"})
      :Times(AtMost(1))
  end

    --===================================================================================--
    --JSON contains empty response array
    function Test:JSONWithInvalidSyntax()

      local UpdateAppListParameters = 
      {
        applications = {
          UpdateAppListParamsStartApp
        }
      }

      ReceivingUpdateAppListaccordingToJsonInSystemRequest(self, "JSON_Validation/JSONWithInvalidSyntax.json", "GENERIC_ERROR", UpdateAppListParameters)

    end

-- TODO: according to APPLINK-19315 add TC with check of max size of response array

function Test:Postcondition_removeCreatedUserConnecttest()
  os.execute(" rm -f  ./user_modules/connecttest_validation_json.lua")
end