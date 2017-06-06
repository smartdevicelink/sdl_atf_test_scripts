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

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
------------Requirement: HMILevel change for rc-apps from driver's device---------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--groups_PrimaryRC Group

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--=================================================BEGIN TEST CASES 4==========================================================--
  --Begin Test suit CommonRequestCheck.4 for Req.#4

  --Description: 4. In case an application with AppHMIType "REMOTE_CONTROL" from driver's device is in HMILevel of FULL and RSDL gets BC.OnAppDeactivated (<any reason>) for this application (= the vehicle HMI User goes either to media embedded HMI screen, or to embedded navigation screen, or to settings menu, or to phonemenu, or to any other non-application HMI menu), RSDL must assign LIMITED HMILevel to this application and send it OnHMIStatus (LIMITED, params) notification.


  --Begin Test case CommonRequestCheck.4.1
  --Description:  --FULL to LIMITED with any reason

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case an application with AppHMIType "REMOTE_CONTROL" from driver's device is in HMILevel of FULL and RSDL gets BC.OnAppDeactivated (<any reason>)

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.4.1.1
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
      --End Test case Precondition.4.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.2
      --Description: activate App1 to FULL
        function Test:TC4_App1FULL()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.4.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.3
      --Description: HMI sends to SDL: OnAppDeactivated (appID_1, *AUDIO*).
        function Test:TC4_DeactivateAUDIO()

          --HMI sends to SDL: OnAppDeactivated (appID_1, *AUDIO*).
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "AUDIO"})

          --App1 side: changing HMILevel to LIMITED
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.4.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.4
      --Description: activate App1 to FULL
        function Test:TC4_App1FULL1()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.4.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.5
      --Description: HMI sends to SDL: OnAppDeactivated (appID_1, *PHONECALL*).
        function Test:TC4_DeactivatePHONECALL()

          --HMI sends to SDL: OnAppDeactivated (appID_1, *PHONECALL*).
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "PHONECALL"})

          --App1 side: changing HMILevel to LIMITED
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.4.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.6
      --Description: activate App1 to FULL
        function Test:TC4_App1FULL2()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.4.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.7
      --Description: HMI sends to SDL: OnAppDeactivated (appID_1, *NAVIGATIONMAP*).
        function Test:TC4_DeactivateNAVIGATIONMAP()

          --HMI sends to SDL: OnAppDeactivated (appID_1, *NAVIGATIONMAP*).
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "NAVIGATIONMAP"})

          --App1 side: changing HMILevel to LIMITED
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.4.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.8
      --Description: activate App1 to FULL
        function Test:TC4_App1FULL3()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.4.1.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.9
      --Description: HMI sends to SDL: OnAppDeactivated (appID_1, *PHONEMENU*).
        function Test:TC4_DeactivatePHONEMENU()

          --HMI sends to SDL: OnAppDeactivated (appID_1, *PHONEMENU*).
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "PHONEMENU"})

          --App1 side: changing HMILevel to LIMITED
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.4.1.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.10
      --Description: activate App1 to FULL
        function Test:TC4_App1FULL4()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.4.1.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.11
      --Description: HMI sends to SDL: OnAppDeactivated (appID_1, *SYNCSETTINGS*).
        function Test:TC4_DeactivateSYNCSETTINGS()

          --HMI sends to SDL: OnAppDeactivated (appID_1, *SYNCSETTINGS*).
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "SYNCSETTINGS"})

          --App1 side: changing HMILevel to LIMITED
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.4.1.11

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.12
      --Description: activate App1 to FULL
        function Test:TC4_App1FULL5()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.4.1.12

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.13
      --Description: HMI sends to SDL: OnAppDeactivated (appID_1, *GENERAL*).
        function Test:TC4_DeactivateGENERAL()

          --HMI sends to SDL: OnAppDeactivated (appID_1, *GENERAL*).
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

          --App1 side: changing HMILevel to LIMITED
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.4.1.13

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.4.1

--=================================================END TEST CASES 4==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end