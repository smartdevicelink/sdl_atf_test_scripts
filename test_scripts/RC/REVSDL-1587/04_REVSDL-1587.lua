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

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()

local device2mac = "f4ef3e7b102431d7f30aa4e2d8020e922c8f6a8c4d159a711d07f28f30ebbaaf"
local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: Send OnHMIStatus("deviceRank") when the device status-------------
---------------------------changes between "driver's" and "passenger's"----------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 4==========================================================--
  --Begin Test suit CommonRequestCheck.4 for Req.#4

  --Description: RSDL must send OnHMIStatus("deviceRank: PASSENGER", params) notification to application(s) registered with REMOTE_CONTROL appHMIType from <deviceID> device


  --Begin Test case CommonRequestCheck.4
  --Description:  --RSDL must send OnHMIStatus("deviceRank: PASSENGER", params) notification to application(s) registered with REMOTE_CONTROL appHMIType from <deviceID> device
              --in case RSDL has treated <deviceID> as driver's
              --AND RSDL gets OnDeviceRankChanged ("DRIVER", <deviceID_2>) notification from HMI (meaning, in case the device the rc-apps are running from is set as passenger's because of another device is chosen as driver's)


    --Requirement/Diagrams id in jira:
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/121955/121955_Req_4_of_Requirement.png

    --Verification criteria:
        --RSDL must send OnHMIStatus("deviceRank: PASSENGER", params) notification to application(s) registered with REMOTE_CONTROL appHMIType from <deviceID> device
              --in case RSDL has treated <deviceID> as driver's
              --AND RSDL gets OnDeviceRankChanged ("DRIVER", <deviceID_2>) notification from HMI (meaning, in case the device the rc-apps are running from is set as passenger's because of another device is chosen as driver's)

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.4
      --Description: Set device1 to Driver's device
        function Test:OnHMIStatus_SetDriverDevice()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
          {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case Precondition.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1
      --Description: Set device2 to Driver's device. After that Device1 become passenger's device
        function Test:OnHMIStatus_SetAnotherDeviceToDriver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
          {deviceRank = "DRIVER", device = {name = "127.0.0.2", id = device2mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for passenger's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "PASSENGER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.4.1

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.4

--=================================================END TEST CASES 4==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end