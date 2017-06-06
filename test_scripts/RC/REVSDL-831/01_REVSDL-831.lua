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
----------Requirement: R-SDL must set first connected device as a "passenger's"---------------
------------one and change this setting upon user's choice delivered from HMI----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--


--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC =  revsdl.arrayGroups_nonPrimaryRC()

--=================================================BEGIN TEST CASES 1==========================================================--
  --Begin Test suit CommonRequestCheck.1 for Req.#1 (TCs: Requirement - [Requirement]: TC_1. Any connected device should be treated as passenger's by RSDL.

  --Description: Rev-SDL must set any connected device independently on transport type as a "passenger's device".

    --Requirement/Diagrams id in jira:
        --Requirement
    --Verification criteria:
        --Rev-SDL must set any connected device independently on transport type as a "passenger's device".

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1
      --Description: Register new session for checking that app on device gets OnPermissionsChange with policies from "group_nonPrimaryRC"
        function Test:PreconditionNewSession()
          --New session1
          self.mobileSession1 = mobile_session.MobileSession(
            self,
            self.mobileConnection)
        end

        function Test:TC_PassengerDevice_App1()
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
                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
                self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
                --[[self.mobileSession1:ExpectNotification("OnPermissionsChange")
                :Do(function(_,data)
                  table.print = print_r
                  table.print( data.payload.permissionItem )
                end)]]

                --check OnHMIStatus with deviceRank = "PASSENGER"
                --self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                --:Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.1.1
    -----------------------------------------------------------------------------------------
    --Begin Test case CommonRequestCheck.1.2
    --Description: Disconnect and then reconnect device to check that app on device gets OnPermissionsChange with policies from "group_nonPrimaryRC"
      --Disconnect device from RSDL by some ways:
              --Send request from mobile UnregisterAppInterface.
              --"Exit" application from mobile.
              --IGNITION_OFF from HMI.
              --Disable Wifi.
              --Stop RSDL.
        function Test:UnregisterAppInterface_Success()

        --mobile side: UnregisterAppInterface request
        local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

        --hmi side: expected  BasicCommunication.OnAppUnregistered
        --EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})

        end
      --Re-connect by some ways:
              --Send request RegisterAppInterface from mobile.
              --Launch application and add session again from mobile.
              --Enable Wifi.
              --Start RSDL again.
        function Test:PreconditionNewSession()
          --New session1
          self.mobileSession1 = mobile_session.MobileSession(
            self,
            self.mobileConnection)
        end

        function Test:TC_PassengerDevice_App2()
            self.mobileSession1:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
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
                self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

                --check OnHMIStatus with deviceRank = "PASSENGER"
                --self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                --:Timeout(3000)

              end)
        end
      --End Test case CommonRequestCheck.1.2

    -----------------------------------------------------------------------------------------
  --End Test Case CommonRequestCheck.1
  --Note: Almost TCs of TRS Requirement are replaced by CRQ RESDLD-1577.

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end