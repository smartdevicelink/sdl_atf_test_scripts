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

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
-----------Requirement: Subscriptions: reset upon device location changed--------------------
---------------------------------via RC.OnDeviceLocationChanged------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--


      --Begin Test case CommonRequestCheck.2.1.0
      --Description: Set Device1 to Driver's device
         function Test:TC2_Pre_SetDevice1ToDriver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})


        end
      -- --End Test case CommonRequestCheck.2.1.0

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.2.1
      --Description: activate App1 to FULL
        function Test:PreconditionActivation()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL" })
        end
      --End Test case CommonRequestCheck.3.2.1


--=================================================BEGIN TEST CASES 3==========================================================--
  --Begin Test suit CommonRequestCheck.3 for Requirement and Requirement

  --Description: 3. Requirement

  --Begin Test case CommonRequestCheck.3.1
  --Description:  Subscriptions taking off - exited app
          --2. USER_EXIT App1 and App2 to hmiLevel=NONE

    --Requirement/Diagrams id in jira:
        --Requirement
        --Requirement

    --Verification criteria:
        -- Policies: Configure app-specific permission to not receive OnInteriorVehicleData notification in NONE level.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.3.1.1
      --Description: Register new session for register new app
        function Test:TC3_Precondition1()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.3.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.2
      --Description: Register App2, App2=NONE for precondition
        function Test:TC3_RegisteredApp2()
          sleep(1)
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
              end)

               --RSDL sends BC.ActivateApp (level: NONE) to HMI.
                EXPECT_HMICALL("BasicCommunication.ActivateApp",
                {
                  appID = self.applications["Test Application1"],
                  level = "NONE",
                  priority = "NONE"
                })


              --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
              self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

              --mobile side: Expect OnPermissionsChange notification for DRIVER's device
              -- arrayGroups_nonPrimaryRC comes wrong in pasa RC too
              -- self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
              self.mobileSession1:ExpectNotification("OnPermissionsChange")

              --mobile side:RSDL sends OnHMIStatus (NONE,params) to mobile application.
              -- deviceRank comes wrong in pasa RC too
              -- self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
              self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

            end)
          end
      --End Test case CommonRequestCheck.3.1.2
    -----------------------------------------------------------------------------------------
      --Begin Test case CommonRequestCheck.3.1.5
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:USER_EXITApp1App2_NONE()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application1"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })

        end
      --End Test case CommonRequestCheck.3.1.5

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end