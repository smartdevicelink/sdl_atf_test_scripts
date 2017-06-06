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

---------------------------------------------------------------------------------------------
--Declaration connected devices.
--1. Device 2:
local device2 = "192.168.100.199"
local device2Port = 12345

local device2mac = "f4ef3e7b102431d7f30aa4e2d8020e922c8f6a8c4d159a711d07f28f30ebbaaf"
local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

os.execute("ifconfig lo:1 192.168.100.199")
---------------------------------------------------------------------------------------------



--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()


---------------------------------------------------------------------------------------------
-------------------------------------STARTING COMMON FUNCTIONS-------------------------------
---------------------------------------------------------------------------------------------

--New connection device2
local function newConnectionDevice2(self, DeviceIP, Port)

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

---------------------------------------------------------------------------------------------
----------------------------------------END COMMON FUNCTIONS---------------------------------
---------------------------------------------------------------------------------------------






--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: A device previously set as "driver's" must be---------------------
------------------------------ switchable to "passenger's"-----------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test suit CommonRequestCheck.2 for Req.#2 (TCs: Requirement - [Requirement][TC-06]: Switch from driver's to passenger's device and vice versa when receiving OnDeviceRankChanged().)

  --Description: In case RSDL knows a device to be driver's and RC.OnDeviceRankChanged ("DRIVER", deviceID) for another device comes from HMI, RSDL must set the named device as driver's and set the previous one to passenger's.


  --Begin Test case CommonRequestCheck.2.1
  --Description:  In case RSDL knows a device to be driver's and RC.OnDeviceRankChanged ("DRIVER", deviceID) for another device comes from HMI, RSDL must set the named device as driver's and set the previous one to passenger's.


    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case RSDL knows a device to be driver's and RC.OnDeviceRankChanged ("DRIVER", deviceID) for another device comes from HMI, RSDL must set the named device as driver's and set the previous one to passenger's.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1
      --Description: Connect device2 for precondition
        function Test:ConnectDevice2()

          newConnectionDevice2(self, device2, device2Port)

        end
      --End Test case Precondition.1

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.2
      --Description: Register App from Device2
        function Test:App1Device2Register()

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
      --End Test case Precondition.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.1
      --Description: Set device1 to Driver's device from HMI
        function Test:OnDeviceRankChanged_Driver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.2.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.2
      --Description: Set device2 to Driver's device from HMI, after that Device1 become Passenger's device.
        function Test:OnDeviceRankChanged_SetAnotherToDriver()

          --hmi side: send request RC.OnDeviceRankChanged to Device2
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = device2, id = device2mac, isSDLAllowed = true}})

          --APP FROM DEVICE1:
          --mobile side: Expect OnPermissionsChange notification for Device1 is Passenger
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          --mobile side: OnHMIStatus notifications with deviceRank = "PASSENGER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })

          --APP FROM DEVICE2:
          self.mobileSession21:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          self.mobileSession21:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.2.1.2

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.2.1


--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end