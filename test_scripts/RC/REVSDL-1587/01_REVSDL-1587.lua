local commonSteps = require("user_modules/shared_testcases/commonSteps")
commonSteps:CheckSDLPath()
commonSteps:DeleteLogsFileAndPolicyTable()

local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
commonPreconditions:ReplaceFile("sdl_preloaded_pt.json", "./files/jsons/RC/rc_sdl_preloaded_pt.json")

local revsdl = require("user_modules/revsdl")

revsdl.AddUnknownFunctionIDs()
revsdl.SubscribeToRcInterface()
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.appID = "8675311"

Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--List of resultscode
local RESULTS_CODE = {"SUCCESS", "WARNINGS", "RESUME_FAILED", "WRONG_LANGUAGE"}

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: Send OnHMIStatus("deviceRank") when the device status-------------
---------------------------changes between "driver's" and "passenger's"----------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--


--=================================================BEGIN TEST CASES 1==========================================================--
  --Begin Test suit CommonRequestCheck.1 for Req.#1

  --Description: Check OnHMIStatus("deviceRank": <appropriate_value>, params) after RegisterAppInterface_response successfully


  --Begin Test case CommonRequestCheck.1
  --Description:  Scenario 1:
        --Device1 is set as passenger's before app_1 registration with SDL


    --Requirement/Diagrams id in jira:
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/121961/121961_Req_1_of_Requirement.png

    --Verification criteria:
        --RSDL must send OnHMIStatus("deviceRank": <appropriate_value>, params) notification to application registered with REMOTE_CONTROL appHMIType after this application successfully registers (after SDL sends RegisterAppInterface_response (<resultCode>, success:true) to such application.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.1
      --Description: Register new session for check OnHMIStatus with deviceRank = "PASSENGER"
        function Test:PreconditionRegistrationApp_Passenger()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1
      --Description: check OnHMIStatus with deviceRank = "PASSENGER"
          function Test:OnHMIStatus_PassengerDevice()
            self.mobileSession1:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
                {
                  syncMsgVersion =
                  {
                  majorVersion = 3,
                  minorVersion = 0
                  },
                  appName = "Test Application2",
                  isMediaApplication = true,
                  languageDesired = 'EN-US',
                  hmiDisplayLanguageDesired = 'EN-US',
                  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                  appID = "1"
                })

                EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                {
                  application =
                  {
                  appName = "Test Application2"
                  }
                })
                :Do(function(_,data)
                  self.applications["Test Application2"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes:
                  --> SUCCESS
                  --> WARNINGS
                  --> RESUME_FAILED
                  --> WRONG_LANGUAGE
                self.mobileSession1:ExpectResponse(CorIdRegister, { success = true })
                :ValidIf (function(_,data)
                  local bSuccess = false
                  for i = 1, #RESULTS_CODE do
                    if data.payload.resultCode == RESULTS_CODE[i] then
                      bSuccess = true
                      break
                    end
                  end
                  if bSuccess then
                    return bSuccess
                  else
                    print( "Actual resultCode: ".. data.payload.resultCode ..". SDL sends RegisterAppInterface_response (success:true) with resultCodes not in {SUCCESS, WARNINGS, RESUME_FAILED, WRONG_LANGUAGE}")
                    return bSuccess
                  end

                end)

                -- check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"} ,{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.2
      --Description: Register new session for check OnHMIStatus with deviceRank = "PASSENGER"
        function Test:PreconditionRegistrationApp_Passenger()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.2
      --Description: check OnHMIStatus with deviceRank = "PASSENGER", RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
          function Test:OnHMIStatus_PassengerDevice_SUCCESS()
            self.mobileSession1:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
                                {
                                  syncMsgVersion =
                                  {
                                    majorVersion = 2,
                                    minorVersion = 2,
                                  },
                                  appName ="SyncProxyTester",
                                  ttsName =
                                  {

                                    {
                                      text ="SyncProxyTester",
                                      type ="TEXT",
                                    },
                                  },
                                  ngnMediaScreenAppName ="SPT",
                                  vrSynonyms =
                                  {
                                    "VRSyncProxyTester",
                                  },
                                  isMediaApplication = true,
                                  languageDesired ="EN-US",
                                  hmiDisplayLanguageDesired ="EN-US",
                                  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                                  appID ="123456",
                                  deviceInfo =
                                  {
                                    hardware = "hardware",
                                    firmwareRev = "firmwareRev",
                                    os = "os",
                                    osVersion = "osVersion",
                                    carrier = "carrier",
                                    maxNumberRFCOMMPorts = 5
                                  }

                                })


              --hmi side: expected  BasicCommunication.OnAppRegistered
              EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                        {
                          application =
                          {
                            appName = "SyncProxyTester",
                            ngnMediaScreenAppName ="SPT",
                            deviceInfo =
                            {
                              id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
                              isSDLAllowed = true,
                              name = "127.0.0.1",
                              transportType = "WIFI"
                            },
                            policyAppID = "123456",
                            hmiDisplayLanguageDesired ="EN-US",
                            isMediaApplication = true,
                            appType =
                            {
                              "NAVIGATION", "REMOTE_CONTROL"
                            }
                          },
                          ttsName =
                          {
                            {
                              text ="SyncProxyTester",
                              type ="TEXT"
                            }
                          },
                          vrSynonyms =
                          {
                            "VRSyncProxyTester"
                          }
                        })
                :Do(function(_,data)
                  self.applications["Test Application2"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes:
                  --> SUCCESS
                self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})

                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.3
      --Description: Register new session for check OnHMIStatus with deviceRank = "PASSENGER"
        function Test:PreconditionRegistrationApp_Passenger()
          self.mobileSession2 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.3
      --Description: check OnHMIStatus with deviceRank = "PASSENGER", RegisterAppInterface_response (success:true) with the following resultCodes: RESUME_FAILED
          function Test:OnHMIStatus_PassengerDevice_RESUME_FAILED()
            self.mobileSession2:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface",
                                {

                                  syncMsgVersion =
                                  {
                                    majorVersion = 2,
                                    minorVersion = 2,
                                  },
                                  appName ="SyncProxyTester2",
                                  isMediaApplication = true,
                                  languageDesired ="EN-US",
                                  hmiDisplayLanguageDesired ="EN-US",
                                  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                                  appID ="1234567",
                                  hashID = "hashID"
                                })

            --hmi side: expected  BasicCommunication.OnAppRegistered
            EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                        {
                            application =
                            {
                              appName = "SyncProxyTester2",
                      appType = { "NAVIGATION", "REMOTE_CONTROL" },
                      policyAppID = "1234567",
                      hmiDisplayLanguageDesired ="EN-US",
                      isMediaApplication = true
                            }
                        })
                :Do(function(_,data)
                  self.applications["SyncProxyTester2"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes:
                  --> RESUME_FAILED
                self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "RESUME_FAILED"})

                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.4
      --Description: Register new session for check OnHMIStatus with deviceRank = "PASSENGER"
        function Test:PreconditionRegistrationApp_Passenger()
          self.mobileSession3 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.4
      --Description: check OnHMIStatus with deviceRank = "PASSENGER", RegisterAppInterface_response (success:true) with the following resultCodes: WRONG_LANGUAGE
          function Test:OnHMIStatus_PassengerDevice_WRONG_LANGUAGE()
            self.mobileSession3:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession3:SendRPC("RegisterAppInterface",
                              {
                                syncMsgVersion =
                                {
                                  majorVersion = 2,
                                  minorVersion = 2,
                                },
                                appName ="SyncProxyTester3",
                                isMediaApplication = true,
                                languageDesired = "DE-DE",
                                hmiDisplayLanguageDesired ="EN-US",
                                appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                                appID ="1234569",
                              })

          --hmi side: expected  BasicCommunication.OnAppRegistered
          EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                            {
                                application =
                                {
                                  appName = "SyncProxyTester3",
                          appType = { "NAVIGATION", "REMOTE_CONTROL" },
                          policyAppID = "1234569",
                          hmiDisplayLanguageDesired ="EN-US",
                          isMediaApplication = true
                                }
                            })
                :Do(function(_,data)
                  self.applications["SyncProxyTester3"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes:
                  --> WRONG_LANGUAGE
                self.mobileSession3:ExpectResponse(CorIdRegister, { success = true, resultCode = "WRONG_LANGUAGE"})

                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.1.4

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.1.1




  --Begin Test case CommonRequestCheck.2
  --Description:  Scenario 2:
        --Device1 is set as driver's before app_1 registration with SDL


    --Requirement/Diagrams id in jira:
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/121961/121961_Req_1_of_Requirement.png

    --Verification criteria:
        --RSDL must send OnHMIStatus("deviceRank": <appropriate_value>, params) notification to application registered with REMOTE_CONTROL appHMIType after this application successfully registers (after SDL sends RegisterAppInterface_response (<resultCode>, success:true) to such application.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.2.1.1
      --Description: Set device1 to Driver's device
        function Test:OnHMIStatus_SetDriverDevice()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

        end
      --End Test case Precondition.2.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.2.1.2
      --Description: Register new session for check OnHMIStatus with deviceRank = "DRIVER"
        function Test:PreconditionRegistrationApp_Driver()
          self.mobileSession4 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.2.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1
      --Description: check OnHMIStatus with deviceRank = "DRIVER"
          function Test:OnHMIStatus_DriverDevice()
            self.mobileSession4:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession4:SendRPC("RegisterAppInterface",
                {
                  syncMsgVersion =
                  {
                  majorVersion = 3,
                  minorVersion = 0
                  },
                  appName = "Test Application4",
                  isMediaApplication = true,
                  languageDesired = 'EN-US',
                  hmiDisplayLanguageDesired = 'EN-US',
                  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                  appID = "4"
                })

                EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                {
                  application =
                  {
                  appName = "Test Application4"
                  }
                })
                :Do(function(_,data)
                  self.applications["Test Application4"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes:
                  --> SUCCESS
                  --> WARNINGS
                  --> RESUME_FAILED
                  --> WRONG_LANGUAGE
                self.mobileSession4:ExpectResponse(CorIdRegister, { success = true })
                :ValidIf (function(_,data)
                  local bSuccess = false
                  for i = 1, #RESULTS_CODE do
                    if data.payload.resultCode == RESULTS_CODE[i] then
                      bSuccess = true
                      break
                    end
                  end
                  if bSuccess then
                    return bSuccess
                  else
                    print( "Actual resultCode: ".. data.payload.resultCode ..". SDL sends RegisterAppInterface_response (success:true) with resultCodes not in {SUCCESS, WARNINGS, RESUME_FAILED, WRONG_LANGUAGE}")
                    return bSuccess
                  end

                end)

                --check OnHMIStatus with deviceRank = "DRIVER"
                self.mobileSession4:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.2.1

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.1.2

--=================================================END TEST CASES 1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end