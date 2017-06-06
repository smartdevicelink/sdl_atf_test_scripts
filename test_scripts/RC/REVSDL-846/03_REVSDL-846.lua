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
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
-------------------------Requirement: R-SDL must inform the app when the ---------------------
---------------------"driver's"/"passenger's" state of the device is changed-----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 3==========================================================--
  --Begin Test suit CommonRequestCheck.3 for Req.#3

  --Description: 3. In case the device's state is changed from "driver's" to "passenger's", RSDL must assign an HMILevel of "NONE" and send OnHMIStatus("NONE") to all remote-control applications from this device.


  --Begin Test case CommonRequestCheck.3
  --Description:  In case the device's state is changed from "driver's" to "passenger's", RSDL must assign an HMILevel of "NONE" and send OnHMIStatus("NONE") to all remote-control applications from this device.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the device's state is changed from "driver's" to "passenger's", RSDL must assign an HMILevel of "NONE" and send OnHMIStatus("NONE") to all remote-control applications from this device.

    -----------------------------------------------------------------------------------------

      --FROM BACKGROUND AND FULL to NONE HMILevel
      --Begin Test case Precondition.3.1
      --Description: Register new session for register new apps
        function Test:TC3_Step1()

          --New session1
          self.mobileSession1 = mobile_session.MobileSession(
            self,
            self.mobileConnection)

          --New session2
          self.mobileSession2 = mobile_session.MobileSession(
            self,
            self.mobileConnection)

          --New session3
          self.mobileSession3 = mobile_session.MobileSession(
            self,
            self.mobileConnection)

        end
      --End Test case Precondition.3.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.2
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=1 to SDL.
          function Test:TC3_Step2_3_4()
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

                --SDL sends OnAppRegistered (appID_1, REMOTE_CONTROL, params).
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

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
                self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

                --SDL assign Level (NONE) and returns to mobile: OnHMIStatus (NONE, params)
                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.3.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.3
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=2 to SDL.
          function Test:TC3_Step5()
            self.mobileSession2:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface",
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
                  appID = "2"
                })

                --SDL sends OnAppRegistered (appID_2, REMOTE_CONTROL, params).
                EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
                {
                  application =
                  {
                  appName = "Test Application2"
                  }
                })
                :Do(function(_,data)
                  self.applications["Test Application2"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
                self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

                --SDL assign Level (NONE) and returns to mobile: OnHMIStatus (NONE, params)
                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.3.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.4
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=3 to SDL.
          function Test:TC3_Step6()
            self.mobileSession3:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession3:SendRPC("RegisterAppInterface",
                {
                  syncMsgVersion =
                  {
                  majorVersion = 3,
                  minorVersion = 0
                  },
                  appName = "Test Application3",
                  isMediaApplication = true,
                  languageDesired = 'EN-US',
                  hmiDisplayLanguageDesired = 'EN-US',
                  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                  appID = "3"
                })

                --SDL sends OnAppRegistered (appID_3, REMOTE_CONTROL, params).
                EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
                {
                  application =
                  {
                  appName = "Test Application3"
                  }
                })
                :Do(function(_,data)
                  self.applications["Test Application3"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
                self.mobileSession3:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

                --SDL assign Level (NONE) and returns to mobile: OnHMIStatus (NONE, params)
                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.3.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.5
      --Description: From appropriate HMI menu set connected device as Driver's device.
        function Test:TC3_Step7()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device for App1, App2, App3
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER" for App1, App2, App3
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.3.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.6
      --Description: From HMI set app1, app2 to Background.
        function Test:TC3_Step8()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application1"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})

        end
        function Test:TC3_Step9()

          --hmi side: sending SDL.ActivateApp request
          local rid2 = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application2"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid2)

          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})

        end
        function Test:TC3_Step10()

          --hmi side: sending SDL.ActivateApp request
          local rid3 = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application3"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid3)

          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
          self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})

        end
      --End Test case CommonRequestCheck.3.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.7
      --Description: From appropriate HMI menu set connected device as NON primary.
        function Test:TC3_Step11()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "PASSENGER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Passenger's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "PASSENGER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })

        end
      --End Test case CommonRequestCheck.3.7

    -----------------------------------------------------------------------------------------

      --REPEAT STEPS FOR BACKGROUND AND LIMITED to NONE HMILevel
      --Begin Test case CommonRequestCheck.3.8
      --Description: From appropriate HMI menu set connected device as Driver's device.
        function Test:TC3_Step12_1()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device for App1, App2, App3
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER" for App1, App2, App3
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.3.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.9
      --Description: From HMI set app1, app2 to Background.
        function Test:TC3_Step12_2()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application1"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})

        end
        function Test:TC3_Step12_3()

          --hmi side: sending SDL.ActivateApp request
          local rid2 = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application2"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid2)

          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})

        end
        function Test:TC3_Step12_4()

          --hmi side: SDL send OnHMIStatus(NONE deviceRank:Driver OnSystemContext=) to mobile app. This notification can be observed on mobile app1.
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application2"], reason = "GENERAL"})

          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

        end
      --End Test case CommonRequestCheck.3.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.10
      --Description: From appropriate HMI menu set connected device as NON primary.
        function Test:TC3_Step12_5()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "PASSENGER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Passenger's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "PASSENGER" for App1, App2, App3
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", deviceRank = "PASSENGER" })
          self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })

        end
      --End Test case CommonRequestCheck.3.10

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.3

--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end