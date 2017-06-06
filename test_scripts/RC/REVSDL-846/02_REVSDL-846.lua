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
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()

--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
-------------------------Requirement: R-SDL must inform the app when the ---------------------
---------------------"driver's"/"passenger's" state of the device is changed-----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test suit CommonRequestCheck.2 for Req.#2

  --Description: 2. In case the device is set as 'passenger's' (see Requirement), R-SDL must assign "groups_nonPrimaryRC" permissions from appropriate policies to each remote-control app from this device.


  --Begin Test case CommonRequestCheck.2
  --Description:  In case the device is set as 'passenger's' (see Requirement), R-SDL must assign "groups_nonPrimaryRC" permissions from appropriate policies to each remote-control app from this device.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the device is set as 'passenger's' (see Requirement), R-SDL must assign "groups_nonPrimaryRC" permissions from appropriate policies to each remote-control app from this device.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.2.1
      --Description: Register new session for register new app
        function Test:TC2_PreconditionRegistrationApp()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2
      --Description: check OnHMIStatus with "OnPermissionsChange" notification
          function Test:TC2_PassengerDevice()
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
                  appID = "1"
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
                self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case CommonRequestCheck.2.2

    -----------------------------------------------------------------------------------------

  --     --Begin Test case CommonRequestCheck.2.3
  --     --Description: From mobile app registered from non primary (passengers device) send disallowed in policy table (groups_NON_PrimaryRC) RPS with allowed seat position.
  --         function Test:TC2_PassengerDevice()

  --           local cid = self.mobileSession:SendRPC("ButtonPress",
  --           {
  --             zone =
  --             {
  --               colspan = 2,
  --               row = 1,
  --               rowspan = 2,
  --               col = 1,
  --               levelspan = 1,
  --               level = 0
  --             },
  --             moduleType = "RADIO",
  --             buttonPressMode = "LONG",
  --             buttonName = "VOLUME_UP"
  --           })


  --           EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })

  --         end
  --     --End Test case CommonRequestCheck.2.3

  --   -----------------------------------------------------------------------------------------


  -- --End Test case CommonRequestCheck.2

--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end