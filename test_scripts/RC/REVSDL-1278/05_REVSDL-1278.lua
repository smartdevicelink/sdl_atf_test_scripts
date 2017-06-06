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

--=================================================BEGIN TEST CASES 5==========================================================--
  --Begin Test suit CommonRequestCheck.5 for Req.#5

  --Description: . --An application with AppHMILevel "NONE" or "BACKGROUND"


  --Begin Test case CommonRequestCheck.5.1
  --Description:  --An application with AppHMIType "REMOTE_CONTROL"
            --An application with AppHMIType "REMOTE_CONTROL"
            --From passenger's device
            --Of LIMITED HMILevel sends an RPC
            --And this RPC is allowed by app's assigned policies
            --And this RPC is from "driver_allow" section (see Requirement for details)
            --And the the permission prompt is either denied by the driver, timed out or unsuccessful
            --RSDL must not change the HMILevel of this app.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement, Requirement

    --Verification criteria:
        --1. Leave passenger's rc-app in BACKGROUND/NONE - NONE case
        --2. Leave passenger's rc-app in BACKGROUND/NONE - BACKGROUND case

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.1
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (Driver denied permission)
        function Test:TC5_NONEDenied()
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

          --hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = false})

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
              :Times(0)
              :Do(function(_,data1)
                --hmi side: sending Buttons.ButtonPress response
                self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
              end)

          end)

          --Check RSDL log: HMI sends RC.GetInteriorVehicleDataConsent(resultCode:SUCCESS, allowed:false) to RSDL and HMILevel of App_1 is not changed.
          self.mobileSession:ExpectNotification("OnHMIStatus")
          :Times(0)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
        end
      --End Test case CommonRequestCheck.5.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.2
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (TIMEOUT 10s)
        function Test:TC5_NONETimeout10s()
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

          --hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
              local function HMIResponse()
                --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
                self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

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
                :Times(0)
                :Do(function(_,data1)
                  --hmi side: sending Buttons.ButtonPress response
                  self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
                end)
              end

              RUN_AFTER(HMIResponse, 10000)
          end)

          --Check RSDL log: HMI sends RC.GetInteriorVehicleDataConsent(resultCode:SUCCESS, allowed:false) to RSDL and HMILevel of App_1 is not changed.
          self.mobileSession:ExpectNotification("OnHMIStatus")
          :Times(0)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
          :Timeout(11000)
        end
      --End Test case CommonRequestCheck.5.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.3
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (Emulation HMI sending the erroneous response)
        function Test:TC5_NONEError()
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

          --hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", {"SUCCESS"}, {allowed = true})

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
              :Times(0)
              :Do(function(_,data1)
                --hmi side: sending Buttons.ButtonPress response
                self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
              end)

          end)

          --Check RSDL log: HMI sends RC.GetInteriorVehicleDataConsent(resultCode:SUCCESS, allowed:false) to RSDL and HMILevel of App_1 is not changed.
          self.mobileSession:ExpectNotification("OnHMIStatus")
          :Times(0)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
        end
      --End Test case CommonRequestCheck.5.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.4
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonPressMode = LONG (changing HMILevel to BACKGROUND)
        function Test:TC5_BACKGROUND()
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
      --End Test case CommonRequestCheck.5.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.5
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (Driver denied permission)
        function Test:TC5_BACKGROUNDDenied()
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

          --hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = false})

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
              :Times(0)
              :Do(function(_,data1)
                --hmi side: sending Buttons.ButtonPress response
                self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
              end)

          end)

          --Check RSDL log: HMI sends RC.GetInteriorVehicleDataConsent(resultCode:SUCCESS, allowed:false) to RSDL and HMILevel of App_1 is not changed.
          self.mobileSession:ExpectNotification("OnHMIStatus")
          :Times(0)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
        end
      --End Test case CommonRequestCheck.5.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.6
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (TIMEOUT 10s)
        function Test:TC5_BACKGROUNDTimeout10s()
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

          --hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
              local function HMIResponse()
                --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
                self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

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
                :Times(0)
                :Do(function(_,data1)
                  --hmi side: sending Buttons.ButtonPress response
                  self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
                end)
              end

              RUN_AFTER(HMIResponse, 10000)
          end)

          --Check RSDL log: HMI sends RC.GetInteriorVehicleDataConsent(resultCode:SUCCESS, allowed:false) to RSDL and HMILevel of App_1 is not changed.
          self.mobileSession:ExpectNotification("OnHMIStatus")
          :Times(0)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
          :Timeout(11000)
        end
      --End Test case CommonRequestCheck.5.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.7
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (Emulation HMI sending the erroneous response)
        function Test:TC5_BACKGROUNDError()
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

          --hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", {"SUCCESS"}, {allowed = true})

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
              :Times(0)
              :Do(function(_,data1)
                --hmi side: sending Buttons.ButtonPress response
                self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
              end)

          end)

          --Check RSDL log: HMI sends RC.GetInteriorVehicleDataConsent(resultCode:SUCCESS, allowed:false) to RSDL and HMILevel of App_1 is not changed.
          self.mobileSession:ExpectNotification("OnHMIStatus")
          :Times(0)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
        end
      --End Test case CommonRequestCheck.5.1.7

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.5.1
--=================================================END TEST CASES 5==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end