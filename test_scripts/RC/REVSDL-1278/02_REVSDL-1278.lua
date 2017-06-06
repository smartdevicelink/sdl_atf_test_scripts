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

--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
------------Requirement: HMILevel change for rc-apps from passenger's device ----------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--


--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test suit CommonRequestCheck.2 for Req.#2

  --Description: 2. --An application with AppHMILevel "BACKGROUND"


  --Begin Test case CommonRequestCheck.2.1
  --Description:  --An application with AppHMIType "REMOTE_CONTROL"
            --From passenger's device
            --Of NONE HMILevel
            --Sends a remote-control RPC
            --And this RPC is allowed by app's assigned policies
            --And this RPC is from "auto_allow" section (see Requirement for details),
            --RSDL must notify this app via OnHMIStatus (BACKGROUND, params) about assigned BACKGROUND HMILevel.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement, Requirement

    --Verification criteria:
        --1. Assign BACKGROUND for passenger's rc-app - by sending RPC from "auto_allow"
        --2. Assign BACKGROUND for passenger's rc-app - by receiving phonecall or emergency occurence notified from HMI

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.1
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonPressMode = LONG (BACKGROUND)
        function Test:TC2_App1BACKGROUND()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 2,
              row = 0,
              rowspan = 2,
              col = 0,
              levelspan = 1,
              level = 0
            },
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "VOLUME_UP"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
                {
                  zone =
                  {
                    colspan = 2,
                    row = 0,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  },
                  moduleType = "RADIO",
                  buttonPressMode = "LONG",
                  buttonName = "VOLUME_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --Mobile side: RSDL sends OnHMIStatus (BACKGROUND,params)
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.2.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.2
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (HMILevel=LIMITED)
        function Test:TC2_App1LIMITED()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("ButtonPress",
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
                  appID = self.applications["Test Application"],
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
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

          self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.2.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.3
      --Description: (refer to defect: Requirement)
              --1. RSDL receives BC.OnPhoneCall(isActive:true) from HMI.
              --2. RSDL returns to mobile: OnHMIStatus(LIMITED, params) notification.
        function Test:TC2_OnPhoneCallLIMITED()

          --hmi side: HMI send BC.OnPhoneCall to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "PHONE_CALL", isActive = true})

          --mobile side: Check that OnHMIStatus(BACKGROUND) sent by RSDL and received by App1
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.2.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.4
      --Description:
              --1. HMI sends to RSDL: BasicCommunication.OnExitApplication(USER_EXIT, appID)
              --2. RSDL returns to App_1: OnHMIStatus(NONE) notification.
        function Test:TC2_PreconditionNONE()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.2.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.5
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (set HMILevel=LIMITED again)
        function Test:TC2_PreconditionApp1LIMITED_2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("ButtonPress",
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
                  appID = self.applications["Test Application"],
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
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

          self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.2.1.5

  --End Test case CommonRequestCheck.2.1
--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end