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

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
------------Requirement: HMILevel change for rc-apps from driver's device---------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--groups_PrimaryRC Group
local arrayGroups_PrimaryRC =  revsdl.arrayGroups_PrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--=================================================BEGIN TEST CASES 3==========================================================--
  --Begin Test suit CommonRequestCheck.3 for Req.#3

  --Description: 3. In case an application with AppHMIType "REMOTE_CONTROL" from driver's device is in HMILevel of LIMITED and the vehicle HMI User activates another non-remote-control application_2, RSDL must leave application_1 in LIMITED HMILevel.


  --Begin Test case CommonRequestCheck.3.1
  --Description:  --1. App1: remoteControl -> (LIMITED)
          --2. App2: non-remoteControl -> (NONE)

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case an application with AppHMIType "REMOTE_CONTROL" from driver's device is in HMILevel of LIMITED and the vehicle HMI User activates another non-remote-control application_2, RSDL must leave application_1 in LIMITED HMILevel.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.3.1.1
      --Description: Register new session for register new app
        function Test:TC3_Precondition1()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)

          self.mobileSession2 = mobile_session.MobileSession(
          self,
          self.mobileConnection)

        end
      --End Test case Precondition.3.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.3.1.2
      --Description: Set device1 to Driver's device from HMI.
        function Test:TC3_Precondition2()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case Precondition.3.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.3
      --Description: Register App1 (non-remoteControl), App1=NONE for precondition
        function Test:TC3_App1NoneRemoteControl()
          self.mobileSession1:StartService(7)
          :Do(function()
              local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
              {
                syncMsgVersion =
                {
                majorVersion = 3,
                minorVersion = 0
                },
                appName = "App1",
                isMediaApplication = false,
                languageDesired = 'EN-US',
                hmiDisplayLanguageDesired = 'EN-US',
                appID = "1"
              })

              EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
              {
                application =
                {
                appName = "App1"
                }
              })
              :Do(function(_,data)

                self.applications["App1"] = data.params.application.appID

              end)

              --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
              self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

              --mobile side:RSDL sends OnHMIStatus (NONE,params) to mobile application.
              self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })

            end)
          end


        function Test:TC3_App2RemoteControl()
          self.mobileSession2:StartService(7)
          :Do(function()
              local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface",
              {
                syncMsgVersion =
                {
                majorVersion = 3,
                minorVersion = 0
                },
                appName = "App2",
                isMediaApplication = false,
                languageDesired = 'EN-US',
                hmiDisplayLanguageDesired = 'EN-US',
                appHMIType = { "REMOTE_CONTROL" },
                appID = "2"
              })

              EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
              {
                application =
                {
                appName = "App2"
                }
              })
              :Do(function(_,data)

                self.applications["App2"] = data.params.application.appID

              end)

              --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
              self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

              --mobile side:RSDL sends OnHMIStatus (NONE,params) to mobile application.
              self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })

            end)
          end
      --End Test case CommonRequestCheck.3.1.3
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.4
      --Description: activate App2 to FULL
        function Test:TC3_Precondition4()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["App2"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
        end
      --End Test case CommonRequestCheck.3.1.4
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.5
      --Description: Go to "Application List" menu on HMI then deactivate App_2
        function Test:TC3_DeactivateApp2()

          --Deactived App1 via go to "Application List" menu on HMI
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["App2"], reason = "GENERAL"})

          --App1 side: changing HMILevel to LIMITED
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.3.1.5
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.6
      --Description: On HMI, activate App_1
              --1. App1: HMIStatus of App_1 is not changed, still keeps LIMITED HMILevel
              --2. App2: SDL returns to mobile: OnHMIStatus (FULL, params)
        function Test:TC3_ActivateApp1()

          --hmi side: On HMI, activate App_1
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["App1"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          --App2 side: SDL returns to mobile: OnHMIStatus (FULL, params)
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})

          --App1 side: HMIStatus of App_1 is not changed, still keeps LIMITED HMILevel
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE"})
          :Times(0)

        end
      --End Test case CommonRequestCheck.3.1.6
    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.3.1

--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end