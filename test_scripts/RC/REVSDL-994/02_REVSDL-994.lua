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

--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test suit CommonRequestCheck.2 for Req.#2

  --Description: 2. In case an application_1 with AppHMIType "REMOTE_CONTROL" from driver's device is in HMILevel of LIMITED and the vehicle HMI User activates another remote-control application_2 from driver's device, RSDL must assign BACKGROUND HMILevel to this application_1 and send it OnHMIStatus (BACKGROUND, params) notification.


  --Begin Test case CommonRequestCheck.2.1
  --Description:  --1. FULL -> BACKGROUND
          --2. LIMITED -> BACKGROUND

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case an application_1 with AppHMIType "REMOTE_CONTROL" from driver's device is in HMILevel of LIMITED and the vehicle HMI User activates another remote-control application_2 from driver's device, RSDL must assign BACKGROUND HMILevel to this application_1 and send it OnHMIStatus (BACKGROUND, params) notification.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.2.1.2
      --Description: Set device1 to Driver's device from HMI.
        function Test:TC2_Precondition2()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case Precondition.2.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.3
      --Description: activate App1 to FULL
        function Test:TC2_Precondition3()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL" })
        end
      --End Test case CommonRequestCheck.2.1.3
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.4
      --Description:
              --1. RSDL receives BC.OnPhoneCall(isActive:true) from HMI.
              --2. RSDL returns to mobile: OnHMIStatus(BACKGROUND, params) notification.
        function Test:TC2_OnPhoneCallFULLToBACKGROUND()

          --hmi side: HMI send BC.OnPhoneCall to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "PHONE_CALL", isActive = true})

          --mobile side: Check that OnHMIStatus(BACKGROUND) sent by RSDL and received by App1
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.2.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.5
      --Description: activate App1 to FULL again
        function Test:TC2_Precondition4()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL" })
        end
      --End Test case CommonRequestCheck.2.1.5
    -----------------------------------------------------------------------------------------

      --REMOVED THIS TESTCASE DUE TO DEFECT: Requirement
      --Begin Test case CommonRequestCheck.2.1.6
      --[[Description:
              --1. HMI sends to RSDL: OnEmergencyEvent(ON)
              --2. RSDL returns to mobile: OnHMIStatus(BACKGROUND, params) notification.
        function Test:TC2_OnEmergencyEventFULLToBACKGROUND()

          --hmi side: HMI send BC.OnPhoneCall to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = true})

          --mobile side: Check that OnHMIStatus(BACKGROUND) sent by RSDL and received by App1
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.2.1.6]]

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.2.1


    -----------------------------------------------------------------------------------------
  --Begin Test case CommonRequestCheck.2.2 (must run CommonRequestCheck.2.1 before for precondition)
  --Description:  --1. FULL -> BACKGROUND
          --2. LIMITED -> BACKGROUND

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case an application_1 with AppHMIType "REMOTE_CONTROL" from driver's device is in HMILevel of LIMITED and the vehicle HMI User activates another remote-control application_2 from driver's device, RSDL must assign BACKGROUND HMILevel to this application_1 and send it OnHMIStatus (BACKGROUND, params) notification.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.2.1.1
      --Description: Register new session for register new app
        function Test:TC2_Precondition1()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.2.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2.1
      --Description: Register App2, App2=NONE for precondition
        function Test:TC2_App2NONE()
          self.mobileSession1:StartService(7)
          :Do(function()
              local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
              {
                syncMsgVersion =
                {
                majorVersion = 3,
                minorVersion = 0
                },
                appName = "Test Application1",
                isMediaApplication = true,
                languageDesired = 'EN-US',
                hmiDisplayLanguageDesired = 'EN-US',
                appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                appID = "1"
              })

              EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
              {
                application =
                {
                appName = "Test Application1"
                }
              })
              :Do(function(_,data)
                self.applications["Test Application1"] = data.params.application.appID

                --RSDL sends BC.ActivateApp (level: NONE) to HMI.
                EXPECT_HMICALL("BasicCommunication.ActivateApp",
                {
                  appID = self.applications["Test Application1"],
                  level = "NONE",
                  priority = "NONE"
                })

              end)

              --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
              self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

              --mobile side: Expect OnPermissionsChange notification for DRIVER's device
              self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

              --mobile side:RSDL sends OnHMIStatus (NONE,params) to mobile application.
              self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

            end)
          end
      --End Test case CommonRequestCheck.2.2.1
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2.2
      --Description: activate App1 to FULL
        function Test:TC2_Precondition4()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application1"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
        end
      --End Test case CommonRequestCheck.2.2.2
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2.3
      --Description: Go to "Application List" menu on HMI then deactivate App_1.
        function Test:TC2_DeactivateApp1()

          --Deactived App1 via go to "Application List" menu on HMI
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application1"], reason = "GENERAL"})

          --App2 side: changing HMILevel to LIMITED
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.2.2.3
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2.3
      --Description: On HMI, activate App_2
              --1. App1: SDL returns to mobile: OnHMIStatus (BACKGROUND, params).
              --2. App2: SDL returns to mobile: OnHMIStatus (FULL, params).
        function Test:TC2_ActivateApp2()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          --App1: SDL returns to mobile: OnHMIStatus (BACKGROUND, params).
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})

          --App2 side: changing HMILevel to FULL
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.2.2.3
    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.2.2

--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end