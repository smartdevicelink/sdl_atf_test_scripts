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
local config = require('config')

--Declaration connected devices.
--1. Device 2:
local device2 = "192.168.100.199"
local device2Port = 12345
--2. Device 3:
local device3 = "10.42.0.1"
local device3Port = 12345

local device3mac = "46a0f15bb1a642f4435f4d228d69d4bd54650f8120d6e796620d8e71e346d620"
local device2mac = "f4ef3e7b102431d7f30aa4e2d8020e922c8f6a8c4d159a711d07f28f30ebbaaf"
local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"


-- Cretion dummy connections fo script
os.execute("ifconfig lo:1 192.168.100.199")
os.execute("ifconfig lo:2 10.42.0.1")


--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
----------Requirement: R-SDL must set first connected device as a "passenger's"---------------
------------one and change this setting upon user's choice delivered from HMI----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--




---------------------------------------------------------------------------------------------
----------------------------------------BEGIN COMMON FUNCTIONS---------------------------------
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

--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC =  revsdl.arrayGroups_nonPrimaryRC()

--=================================================BEGIN TEST CASES 3==========================================================--
  --Begin Test suit CommonRequestCheck.3 for Req.#3 (multi devices - 3 devices)

  --Description: In case RSDL knows a device to be driver's and RC.OnSetDriversDevice for another device comes from HMI, RSDL must set the named device as driver's and set the previous one to passenger's.


  --Begin Test case CommonRequestCheck.3.1
  --Description:  In case RSDL knows a device to be driver's and RC.OnSetDriversDevice for another device comes from HMI, RSDL must set the named device as driver's and set the previous one to passenger's.


    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --In case RSDL knows a device to be driver's and RC.OnSetDriversDevice for another device comes from HMI, RSDL must set the named device as driver's and set the previous one to passenger's.


    -----------------------------------------------------------------------------------------
      --Begin Test case CommonRequestCheck.3.1.1
      --Description: Connecting Device1 to RSDL
      function Test:ConnectDevice1()
        newConnectionDevice2(self, device2, device2Port)

      end
      --End Test case CommonRequestCheck.3.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.2
      --Description: Connecting Device2 to RSDL
        function Test:ConnectDevice2()

          newConnectionDevice3(self, device3, device3Port)

        end
      --End Test case CommonRequestCheck.3.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.3
      --Description: Register new session for register new apps
        function Test:TC3_NewApps()
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
      --End Test case CommonRequestCheck.3.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.4
      --Description: Register App3 from Device2
         function Test:TC3_App3Device2()

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
      --End Test case CommonRequestCheck.3.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.5
      --Description: Register App4 from Device2
         function Test:TC3_App4Device2()

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
      --End Test case CommonRequestCheck.3.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.6
      --Description: Register App2 from Device1
         function Test:TC3_App2Device1()

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
      --End Test case CommonRequestCheck.3.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.7
      --Description: Register App5 from Device3
        --Device3
         function Test:TC3_App5Device3()

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
      --End Test case CommonRequestCheck.3.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.8
      --Description: Register App6 from Device3
         function Test:TC3_App6Device3()

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
      --End Test case CommonRequestCheck.3.1.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.9
      --Description: Set device2 to Driver's device from HMI.
        function Test:TC3_SetDevice2Driver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = device2, id = device2mac, isSDLAllowed = true}})

          --Device2: App3,4: gets OnPermissionsChange with policies from "groups_PrimaryRC"
          self.mobileSession21:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession22:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

        end
      --End Test case CommonRequestCheck.3.1.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.10
      --Description: Set device1 to Driver's device from HMI.
        function Test:TC3_SetDevice1Driver()

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
      --End Test case CommonRequestCheck.3.1.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.11
      --Description: Set device3 to Driver's device from HMI.
        function Test:TC3_SetDevice3Driver()

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
      --End Test case CommonRequestCheck.3.1.11

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.3.1

--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end