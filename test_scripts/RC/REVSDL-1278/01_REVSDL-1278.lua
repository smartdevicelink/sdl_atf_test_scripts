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
------------Requirement: HMILevel change for rc-apps from passenger's device ----------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--


--=================================================BEGIN TEST CASES 1==========================================================--
  --Begin Test suit CommonRequestCheck.1 for Req.#1

  --Description: 1. In case an application with AppHMIType "REMOTE_CONTROL" successfully registers from passenger's device at SDL and this application is not present in HMILevel resumption list, RSDL must notify this app via OnHMIStatus (NONE, params) about assigned NONE HMILevel.


  --Begin Test case CommonRequestCheck.1.1
  --Description:  In case an application with AppHMIType "REMOTE_CONTROL" successfully registers from passenger's device at SDL and this application is not present in HMILevel resumption list, RSDL must notify this app via OnHMIStatus (NONE, params) about assigned NONE HMILevel.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement, Requirement

    --Verification criteria:
        --1. Assign NONE for passenger's rc-app - by RegisterAppInterface
        --2. Assign NONE for passenger's rc-app - by using 'exit' command from vehicle HMI

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.1.1.1
      --Description: Register new session for register new app
        function Test:TC1_Precondition1()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.1.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.2
      --Description: Check that RSDL notified connected mobile app via OnHMIStatus (NONE, params) about assigned NONE HMILevel.
        function Test:TC1_App1NONE()
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
                })

              end)

              --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
              self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

              --mobile side: Expect OnPermissionsChange notification for Passenger's device
              self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

              --check OnHMIStatus with deviceRank = "PASSENGER"
              self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"},{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
              :Times(2):Timeout(5000)

            end)
          end
      --End Test case CommonRequestCheck.1.1.2
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.3
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (HMILevel=LIMITED)
        function Test:TC1_App1LIMITED()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession1:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 2,
              row = 0,
              rowspan = 2,
              col = 1,
              levelspan = 1,
              level = 0
            },
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "VOLUME_UP"
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
                  moduleType = "RADIO",
                  zone =
                  {
                    colspan = 2,
                    row = 0,
                    rowspan = 2,
                    col = 1,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect Buttons.ButtonPress request
              EXPECT_HMICALL("Buttons.ButtonPress",
                      {
                        zone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 1,
                          levelspan = 1,
                          level = 0
                        },
                        moduleType = "RADIO",
                        buttonPressMode = "LONG",
                        buttonName = "VOLUME_UP"
                      })
                :Do(function(_,data1)
                  --hmi side: sending Buttons.ButtonPress response
                  self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
                end)
          end)

          --Mobile side: RSDL sends OnHMIStatus (LIMITED,params)
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.4
      --Description:
              --1. HMI sends to RSDL: BasicCommunication.OnExitApplication(USER_EXIT, appID)
              --2. RSDL returns to App_1: OnHMIStatus(NONE) notification.
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application1"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.1.1.4

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.1.1

--=================================================END TEST CASES 1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end