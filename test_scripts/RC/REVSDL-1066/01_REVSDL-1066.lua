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

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
-----------Requirement: RSDL must inform HMILevel of a rc-application to HMI ----------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--


--=================================================BEGIN TEST CASES 1==========================================================--
  --Begin Test suit CommonRequestCheck.1 for Req.#1

  --Description: 1. In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from driver's device is changed (see Requirement for details), RSDL must inform this event via BC.ActivateApp (level: <appropriate assigned HMILevel of the app>) to HMI.
            --Exception: FULL level (that is, RSDL must not notify HMI about the rc-app has transitioned to FULL).


  --Begin Test case CommonRequestCheck.1.4
  --Description:  In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from driver's device is changed (see Requirement for details), RSDL must inform this event via BC.ActivateApp (level: <appropriate assigned HMILevel of the app>) to HMI.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the device is set as 'driver's' (see Requirement), R-SDL must assign "groups_primaryRC" permissions from appropriate policies to each remote-control app from this device.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.4.1
      --Description: Set device1 to Driver's device from HMI.
        function Test:TC4_Precondition1()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case Precondition.1.4.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.4.2
      --Description: activate App1 from NONE to FULL
        function Test:TC4_NoneToFULL()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --HMILevel of App_1 becomes FULL and RSDL doesn't send BC.ActivateApp to HMI.
          EXPECT_HMICALL("BasicCommunication.ActivateApp",
            {
              appID = self.applications["Test Application"],
              level = "FULL",
              priority = "NONE"
            }
          )
          :Times(0)

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          --Mobile side: RSDL sends OnHMIStatus (FULL,params) to mobile application.
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.1.4.2
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.4.3
      --Description: activate App1 to LIMITED
        function Test:TC4_DeactivatedApp1_LIMITED()

          --hmi side: Go to "Application List" menu on HMI then deactivate App_1 to make HMILevel = LIMITED.
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

          --RSDL sends BC.ActivateApp (level: LIMITED) to HMI
          EXPECT_HMICALL("BasicCommunication.ActivateApp",
            {
              appID = self.applications["Test Application"],
              level = "LIMITED",
              priority = "NONE"
            }
          )

          --Mobile side: RSDL sends OnHMIStatus (BACKGROUND,params)
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})

        end
      --End Test case CommonRequestCheck.1.4.3
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.4.4
      --Description: activate App1 from LIMITED to FULL
        function Test:TC4_LimitedToFULL()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --HMILevel of App_1 becomes FULL and RSDL doesn't send BC.ActivateApp to HMI.
          EXPECT_HMICALL("BasicCommunication.ActivateApp",
            {
              appID = self.applications["Test Application"],
              level = "FULL",
              priority = "NONE"
            }
          )
          :Times(0)

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          --Mobile side: RSDL sends OnHMIStatus (FULL,params) to mobile application.
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.1.4.4
    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.4.5
      --Description: Register new session for register new app
        function Test:TC4_Precondition2()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.1.4.5

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.4.6
      --Description: Register App2 from Device1
        function Test:TC4_Precondition3()
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

                --RSDL sends BC.ActivateApp (level: NONE) to HMI
                EXPECT_HMICALL("BasicCommunication.ActivateApp",
                  {
                    appID = self.applications["Test Application1"],
                    level = "NONE",
                    priority = "NONE"
                  },
                  {
                    appID = self.applications["Test Application"],
                    level = "LIMITED",
                    priority = "NONE"
                  }
                )
                :Times(2)
                :Do(function(_,_)
                  --Deactived App1 to LIMITED after register App2
                  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
                end)

              end)

              --App2 side: SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
              self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

              --App2 side: side: Expect OnPermissionsChange notification for Driver's device
              self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

              --App2 side: check OnHMIStatus with HMILEVEL NONE and deviceRank = "DRIVER"
              self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
              :Timeout(5000)

              --App1 side: changing HMILevel to LIMITED
              self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})
              :Timeout(5000)

          end)
        end
      --End Test case Precondition.1.4.6
    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.4.7
      --Description: activate App2 to FULL (App1 becomes BACKGROUND)
        function Test:TC4_Precondition4_App1LIMITED()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application1"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          --RSDL sends BC.ActivateApp to HMI for App1 and App2
          EXPECT_HMICALL("BasicCommunication.ActivateApp",
            {
              appID = self.applications["Test Application"],
              level = "BACKGROUND",
              priority = "NONE"
            }
          )

          --App1 side: RSDL sends OnHMIStatus (BACKGROUND,params)
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND"})

          --App2 side: RSDL sends OnHMIStatus (FULL,params)
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})

        end
      --End Test case Precondition.1.4.7
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.4.8
      --Description: activate App1 from BACKGROUND to FULL
        function Test:TC4_BackgroundToFULL()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --HMILevel of App_1 becomes FULL and RSDL doesn't send BC.ActivateApp to HMI. (Only sends for App2 FULL -> LIMITED)
          EXPECT_HMICALL("BasicCommunication.ActivateApp",
            {
              appID = self.applications["Test Application1"],
              level = "LIMITED",
              priority = "NONE"
            }
          )
          :Times(1)

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          --App1 side: RSDL sends OnHMIStatus (FULL,params) to mobile application.
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})

          --App2 side: RSDL sends OnHMIStatus (LIMITED,params) to mobile application.
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

        end
      --End Test case CommonRequestCheck.1.4.8
    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.1.4

--=================================================END TEST CASES 1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
