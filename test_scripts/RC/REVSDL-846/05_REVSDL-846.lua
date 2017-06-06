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
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

--Declaration connected devices.
--1. Device 2:
local device2 = "192.168.100.199"
local device2Port = 12345
--2. Device 3:
local device3 = "10.42.0.1"
local device3Port = 12345

os.execute("ifconfig lo:1 192.168.100.199")
os.execute("ifconfig lo:2 10.42.0.1")

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()

local device3mac = "46a0f15bb1a642f4435f4d228d69d4bd54650f8120d6e796620d8e71e346d620"
local device2mac = "f4ef3e7b102431d7f30aa4e2d8020e922c8f6a8c4d159a711d07f28f30ebbaaf"
local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

---------------------------------------------------------------------------------------------
-------------------------------------STARTING COMMON FUNCTIONS-------------------------------
---------------------------------------------------------------------------------------------

--New connection device2
function newConnectionDevice2(self, DeviceIP, Port)

  local tcpConnection = tcp.Connection(DeviceIP, Port)
  local fileConnection = file_connection.FileConnection("mobile2.out", tcpConnection)
  self.mobileConnection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession21 = mobile_session.MobileSession(
    self,
    self.mobileConnection2,
    config.application1.registerAppInterfaceParams
  )
  event_dispatcher:AddConnection(self.mobileConnection2)
  self.mobileSession21:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection2:Connect()
end

--New connection device3
function newConnectionDevice3(self, DeviceIP1, Port)

  local tcpConnection = tcp.Connection(DeviceIP1, Port)
  local fileConnection = file_connection.FileConnection("mobile3.out", tcpConnection)
  self.mobileConnection3 = mobile.MobileConnection(fileConnection)
  self.mobileSession31 = mobile_session.MobileSession(
    self,
    self.mobileConnection3,
    config.application1.registerAppInterfaceParams
  )
  event_dispatcher:AddConnection(self.mobileConnection3)
  self.mobileSession31:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection3:Connect()
end

---------------------------------------------------------------------------------------------
----------------------------------------END COMMON FUNCTIONS---------------------------------
---------------------------------------------------------------------------------------------






--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
-------------------------Requirement: R-SDL must inform the app when the ---------------------
---------------------"driver's"/"passenger's" state of the device is changed-----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 5==========================================================--
  --Begin Test suit CommonRequestCheck.5.1 for Req.#5

  --Description: 5. In case the device's "driver's"/"passenger's" state is either changed from one to another or initially set, Rev-SDL must notify each app registered from such device via OnPermissionsChange notification about changed policy permission.


  --Begin Test case CommonRequestCheck.5.1
  --Description:  In case the device's "driver's"/"passenger's" state is either changed from one to another or initially set, Rev-SDL must notify each app registered from such device via OnPermissionsChange notification about changed policy permission.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement (SKIP STEP4 BECAUSE OF CONNECTING TWO DEVICES)

    --Verification criteria:
        --5. In case the device's "driver's"/"passenger's" state is either changed from one to another or initially set, Rev-SDL must notify each app registered from such device via OnPermissionsChange notification about changed policy permission.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.5.1
      --Description: Register new session for register new apps
        function Test:TC5_Step1_1()

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
      --End Test case Precondition.5.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.2
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=1 to SDL.
          function Test:TC5_Step1_2()
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
                self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER"})
                :Times(2)
              end)
            end
      --End Test case CommonRequestCheck.5.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.3
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=2 to SDL.
          function Test:TC5_Step1_3()
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
                :Times(2)
              end)
            end
      --End Test case CommonRequestCheck.5.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.4
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=3 to SDL.
          function Test:TC5_Step1_4()
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
                self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER"})
                :Times(2)
              end)
            end
      --End Test case CommonRequestCheck.5.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.5
      --Description: From appropriate HMI menu set connected device as Driver's device.
              -- Rev-SDL must notify each app registered from such device via OnPermissionsChange(List of assigned permissions)
        function Test:TC5_Step2()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device for App1, App2, App3
                -- Rev-SDL must notify each app registered from such device via OnPermissionsChange(List of assigned permissions)
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
      --End Test case CommonRequestCheck.5.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.6
      --Description: From appropriate HMI menu set connected device as Passenger's device.
              -- Rev-SDL must notify each app registered from such device via OnPermissionsChange(List of assigned permissions)
        function Test:TC5_Step3()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "PASSENGER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for PASSENGER's device for App1, App2, App3
                -- Rev-SDL must notify each app registered from such device via OnPermissionsChange(List of assigned permissions)
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "PASSENGER" for App1, App2, App3
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })

        end
      --End Test case CommonRequestCheck.5.1.6

    -----------------------------------------------------------------------------------------

      --REPEAT STEP2, STEP3 ONE MORE TIME:
      --Begin Test case CommonRequestCheck.5.1.7
      --Description: From appropriate HMI menu set connected device as Driver's device.
              -- Rev-SDL must notify each app registered from such device via OnPermissionsChange(List of assigned permissions)
        function Test:TC5_Step3_RepeatStep2()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device for App1, App2, App3
                -- Rev-SDL must notify each app registered from such device via OnPermissionsChange(List of assigned permissions)
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
      --End Test case CommonRequestCheck.5.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.8
      --Description: From appropriate HMI menu set connected device as Passenger's device.
              -- Rev-SDL must notify each app registered from such device via OnPermissionsChange(List of assigned permissions)
        function Test:TC5_Step3_RepeatStep3()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "PASSENGER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for PASSENGER's device for App1, App2, App3
                -- Rev-SDL must notify each app registered from such device via OnPermissionsChange(List of assigned permissions)
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "PASSENGER" for App1, App2, App3
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })

        end
      --End Test case CommonRequestCheck.5.1.8

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.5.1


  --Begin Test case CommonRequestCheck.5.2
  --Description:  In case the device's "driver's"/"passenger's" state is either changed from one to another or initially set, Rev-SDL must notify each app registered from such device via OnPermissionsChange notification about changed policy permission.


    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --In case the device's "driver's"/"passenger's" state is either changed from one to another or initially set, Rev-SDL must notify each app registered from such device via OnPermissionsChange notification about changed policy permission.

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.1
      --Description: Set device1 to Driver's device from HMI
        function Test:TC5_Driver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.5.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.2
      --Description: Set device1 to Passenger's device from HMI
        function Test:TC5_Passenger()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "PASSENGER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Passenger's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "PASSENGER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })

        end
      --End Test case CommonRequestCheck.5.2.1

    -----------------------------------------------------------------------------------------
      --Begin Test case CommonRequestCheck.5.2.3
      --Description: Connecting Device1 to RSDL
      function Test:TC5_ConnectDevice1()
        newConnectionDevice2(self, device2, device2Port)

      end
      --End Test case CommonRequestCheck.5.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.4
      --Description: Connecting Device2 to RSDL
        function Test:TC5_ConnectDevice2()

          newConnectionDevice3(self, device3, device3Port)

        end
      --End Test case CommonRequestCheck.5.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.5
      --Description: Register new session for register new apps
        function Test:TC5_NewApps()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)

          self.mobileSession22 = mobile_session.MobileSession(
          self,
          self.mobileConnection2)

          self.mobileSession32 = mobile_session.MobileSession(
          self,
          self.mobileConnection3)

        end
      --End Test case CommonRequestCheck.5.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.6
      --Description: Register App3 from Device2
         function Test:TC5_App3Device2()

        --mobile side: RegisterAppInterface request
          self.mobileSession21:StartService(7)
          :Do(function()
           local CorIdRAI = self.mobileSession21:SendRPC("RegisterAppInterface",
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
                text ="4005",
                type ="PRE_RECORDED",
               },
              },
              isMediaApplication = true,
              languageDesired ="EN-US",
              hmiDisplayLanguageDesired ="EN-US",
              appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
              appID ="123456",

               })

           --mobile side: RegisterAppInterface response
           self.mobileSession21:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
          end)

         end
      --End Test case CommonRequestCheck.5.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.7
      --Description: Register App4 from Device2
         function Test:TC5_App4Device2()

        --mobile side: RegisterAppInterface request
          self.mobileSession22:StartService(7)
          :Do(function()
           local CorIdRAI = self.mobileSession22:SendRPC("RegisterAppInterface",
               {

              syncMsgVersion =
              {
               majorVersion = 2,
               minorVersion = 2,
              },
              appName ="SyncProxyTester2",
              ttsName =
              {

               {
                text ="4005",
                type ="PRE_RECORDED",
               },
              },
              isMediaApplication = true,
              languageDesired ="EN-US",
              hmiDisplayLanguageDesired ="EN-US",
              appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
              appID ="1234567",

               })

           --mobile side: RegisterAppInterface response
           self.mobileSession22:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
          end)

         end
      --End Test case CommonRequestCheck.5.2.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.8
      --Description: Register App2 from Device1
         function Test:TC5_App2Device1()

        --mobile side: RegisterAppInterface request
          self.mobileSession1:StartService(7)
          :Do(function()
           local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
               {

              syncMsgVersion =
              {
               majorVersion = 2,
               minorVersion = 2,
              },
              appName ="SyncProxyTester App1",
              ttsName =
              {

               {
                text ="4005",
                type ="PRE_RECORDED",
               },
              },
              isMediaApplication = true,
              languageDesired ="EN-US",
              hmiDisplayLanguageDesired ="EN-US",
              appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
              appID ="1234568",

               })

           --mobile side: RegisterAppInterface response
           self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
          end)

         end
      --End Test case CommonRequestCheck.5.2.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.9
      --Description: Register App5 from Device3
        --Device3
         function Test:TC5_App5Device3()

        --mobile side: RegisterAppInterface request
          self.mobileSession31:StartService(7)
          :Do(function()
           local CorIdRAI = self.mobileSession31:SendRPC("RegisterAppInterface",
               {

              syncMsgVersion =
              {
               majorVersion = 2,
               minorVersion = 2,
              },
              appName ="SyncProxyTester31",
              ttsName =
              {

               {
                text ="4005",
                type ="PRE_RECORDED",
               },
              },
              isMediaApplication = true,
              languageDesired ="EN-US",
              hmiDisplayLanguageDesired ="EN-US",
              appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
              appID ="8888",

               })

           --mobile side: RegisterAppInterface response
           self.mobileSession31:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
          end)

         end
      --End Test case CommonRequestCheck.5.2.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.10
      --Description: Register App6 from Device3
         function Test:TC5_App6Device3()

        --mobile side: RegisterAppInterface request
          self.mobileSession32:StartService(7)
          :Do(function()
           local CorIdRAI = self.mobileSession32:SendRPC("RegisterAppInterface",
               {

              syncMsgVersion =
              {
               majorVersion = 2,
               minorVersion = 2,
              },
              appName ="SyncProxyTester32",
              ttsName =
              {

               {
                text ="4005",
                type ="PRE_RECORDED",
               },
              },
              isMediaApplication = true,
              languageDesired ="EN-US",
              hmiDisplayLanguageDesired ="EN-US",
              appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
              appID ="9999",

               })

           --mobile side: RegisterAppInterface response
           self.mobileSession32:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
          end)

         end
      --End Test case CommonRequestCheck.5.2.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.11
      --Description: Set device2 to Driver's device from HMI.
        function Test:TC5_SetDevice2Driver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = device2, id = device2mac, isSDLAllowed = true}})

          --Device2: App3,4: gets OnPermissionsChange with policies from "groups_PrimaryRC"
          self.mobileSession21:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession22:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

        end
      --End Test case CommonRequestCheck.5.2.11

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.12
      --Description: Set device1 to Driver's device from HMI.
        function Test:TC5_SetDevice1Driver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --Device1: (App1, App2)
          self.mobileSession:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

          --Device2: (App3, App4)
          self.mobileSession21:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession22:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

        end
      --End Test case CommonRequestCheck.5.2.12

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2.13
      --Description: Set device3 to Driver's device from HMI.
        function Test:TC5_SetDevice3Driver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = device3, id = device3mac, isSDLAllowed = true}})

          --Device1: (App1, App2)
          self.mobileSession:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

          --Device3: (App5, App6)
          self.mobileSession31:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession32:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

        end
      --End Test case CommonRequestCheck.5.2.13

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.5.2
--=================================================END TEST CASES 5==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end