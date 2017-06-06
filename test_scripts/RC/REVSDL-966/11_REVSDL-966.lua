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
-----------Requirement: "Allow", "Ask Driver" or "Disallow" permissions - depending-----------
------------------on zone value in RPC and this zone permissions in Policies-----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

---------------------NOTE: THIS SCRIPT ONLY TEST FOR PASSENGER'S DEVICE----------------------

--=================================================BEGIN TEST CASES 11==========================================================--
  --Begin Test suit CommonRequestCheck.11 for Req.#11

  --Description: 11. In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          --and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section
          --and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent
          --and RSDL has processed this (app's initial) RPC
          --and RSDL gets BC.OnExitApplication (USER_EXIT) for this application from HMI
          --RSDL must take off the driver's permissions from this application (that is, trigger a permission prompt upon this app's next controlling request)


  --Begin Test case CommonRequestCheck.11.1
  --Description:  For ButtonPress

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.1.1
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
        function Test:ButtonPress_DriverAllowFrontRADIO_Time1()
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
                :Do(function(_,data)
                  --hmi side: sending Buttons.ButtonPress response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.1.2
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.11.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.1.3
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
        function Test:ButtonPress_DriverAllowFrontRADIO_Time2()
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
                :Do(function(_,data)
                  --hmi side: sending Buttons.ButtonPress response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.1.4
      --Description: application sends ButtonPress as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE
        function Test:ButtonPress_DriverAllowLeftCLIMATE_Time1()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 2,
              row = 1,
              rowspan = 2,
              col = 0,
              levelspan = 1,
              level = 0
            },
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "LOWER_VENT"
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "CLIMATE",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
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
                          row = 1,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        },
                        moduleType = "CLIMATE",
                        buttonPressMode = "SHORT",
                        buttonName = "LOWER_VENT"
                      })
                :Do(function(_,data)
                  --hmi side: sending Buttons.ButtonPress response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.1.5
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.11.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.1.6
      --Description: application sends ButtonPress as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE
        function Test:ButtonPress_DriverAllowLeftCLIMATE_Time2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 2,
              row = 1,
              rowspan = 2,
              col = 0,
              levelspan = 1,
              level = 0
            },
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "LOWER_VENT"
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "CLIMATE",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
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
                          row = 1,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        },
                        moduleType = "CLIMATE",
                        buttonPressMode = "SHORT",
                        buttonName = "LOWER_VENT"
                      })
                :Do(function(_,data)
                  --hmi side: sending Buttons.ButtonPress response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.1.6

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.11.1


  --Begin Test case CommonRequestCheck.11.2
  --Description:  For GetInteriorVehicleData

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.1
      --Description: application sends GetInteriorVehicleData as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
        function Test:GetInterior_DriverAllowFrontRADIO_Time1()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "RADIO",
              moduleZone =
              {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = 1,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
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

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 1,
                          colspan = 2,
                          level = 0,
                          levelspan = 1,
                          row = 0,
                          rowspan = 2
                        },
                        radioControlData = {
                          frequencyInteger = 99,
                          frequencyFraction = 3,
                          band = "FM",
                          rdsData = {
                            PS = "name",
                            RT = "radio",
                            CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                            PI = "Sign",
                            PTY = 1,
                            TP = true,
                            TA = true,
                            REG = "Murica"
                          },
                          availableHDs = 3,
                          hdChannel = 1,
                          signalStrength = 50,
                          signalChangeThreshold = 60,
                          radioEnable = true,
                          state = "ACQUIRING"
                        }
                      }
                  })

              end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.2
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.11.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.3
      --Description: application sends GetInteriorVehicleData as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
        function Test:GetInterior_DriverAllowFrontRADIO_Time2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "RADIO",
              moduleZone =
              {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = 1,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
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

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 1,
                          colspan = 2,
                          level = 0,
                          levelspan = 1,
                          row = 0,
                          rowspan = 2
                        },
                        radioControlData = {
                          frequencyInteger = 99,
                          frequencyFraction = 3,
                          band = "FM",
                          rdsData = {
                            PS = "name",
                            RT = "radio",
                            CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                            PI = "Sign",
                            PTY = 1,
                            TP = true,
                            TA = true,
                            REG = "Murica"
                          },
                          availableHDs = 3,
                          hdChannel = 1,
                          signalStrength = 50,
                          signalChangeThreshold = 60,
                          radioEnable = true,
                          state = "ACQUIRING"
                        }
                      }
                  })

              end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.2
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO
        function Test:GetInterior_DriverAllowLeftRADIO_Time1()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "RADIO",
              moduleZone =
              {
                colspan = 2,
                row = 1,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "RADIO",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 0,
                          colspan = 2,
                          level = 0,
                          levelspan = 1,
                          row = 1,
                          rowspan = 2
                        },
                        radioControlData = {
                          frequencyInteger = 99,
                          frequencyFraction = 3,
                          band = "FM",
                          rdsData = {
                            PS = "name",
                            RT = "radio",
                            CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                            PI = "Sign",
                            PTY = 1,
                            TP = true,
                            TA = true,
                            REG = "Murica"
                          },
                          availableHDs = 3,
                          hdChannel = 1,
                          signalStrength = 50,
                          signalChangeThreshold = 60,
                          radioEnable = true,
                          state = "ACQUIRING"
                        }
                      }
                  })

              end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.3
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.11.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.4
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO
        function Test:GetInterior_DriverAllowLeftRADIO_Time2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "RADIO",
              moduleZone =
              {
                colspan = 2,
                row = 1,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "RADIO",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 0,
                          colspan = 2,
                          level = 0,
                          levelspan = 1,
                          row = 1,
                          rowspan = 2
                        },
                        radioControlData = {
                          frequencyInteger = 99,
                          frequencyFraction = 3,
                          band = "FM",
                          rdsData = {
                            PS = "name",
                            RT = "radio",
                            CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                            PI = "Sign",
                            PTY = 1,
                            TP = true,
                            TA = true,
                            REG = "Murica"
                          },
                          availableHDs = 3,
                          hdChannel = 1,
                          signalStrength = 50,
                          signalChangeThreshold = 60,
                          radioEnable = true,
                          state = "ACQUIRING"
                        }
                      }
                  })

              end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.5
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE
        function Test:GetInterior_DriverAllowLeftCLIMATE_Time1()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                colspan = 2,
                row = 1,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "CLIMATE",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                    moduleData =
                    {
                      moduleType = "CLIMATE",
                      moduleZone =
                      {
                        colspan = 2,
                        row = 1,
                        rowspan = 2,
                        col = 0,
                        levelspan = 1,
                        level = 0
                      },
                      climateControlData =
                      {
                        fanSpeed = 50,
                        circulateAirEnable = true,
                        dualModeEnable = true,
                        currentTemp = 30,
                        defrostZone = "FRONT",
                        acEnable = true,
                        desiredTemp = 24,
                        autoModeEnable = true,
                        temperatureUnit = "CELSIUS"
                      }
                    }
                  })

              end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.6
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.11.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.2.7
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE
        function Test:GetInterior_DriverAllowLeftCLIMATE_Time2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                colspan = 2,
                row = 1,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "CLIMATE",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                    moduleData =
                    {
                      moduleType = "CLIMATE",
                      moduleZone =
                      {
                        colspan = 2,
                        row = 1,
                        rowspan = 2,
                        col = 0,
                        levelspan = 1,
                        level = 0
                      },
                      climateControlData =
                      {
                        fanSpeed = 50,
                        circulateAirEnable = true,
                        dualModeEnable = true,
                        currentTemp = 30,
                        defrostZone = "FRONT",
                        acEnable = true,
                        desiredTemp = 24,
                        autoModeEnable = true,
                        temperatureUnit = "CELSIUS"
                      }
                    }
                  })

              end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.2.7

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.11.2


  --Begin Test case CommonRequestCheck.11.3
  --Description:  For SetInteriorVehicleData

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.3.1
      --Description: application sends SetInteriorVehicleData as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
        function Test:SetInterior_DriverAllowFrontRADIO_Time1()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 0,
                rowspan = 2
              },
              radioControlData = {
                frequencyInteger = 99,
                frequencyFraction = 3,
                band = "FM",
                rdsData = {
                  PS = "name",
                  RT = "radio",
                  CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                  PI = "Sign",
                  PTY = 1,
                  TP = true,
                  TA = true,
                  REG = "Murica"
                },
                availableHDs = 3,
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
            }
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

              --hmi side: expect RC.SetInteriorVehicleData request
              EXPECT_HMICALL("RC.SetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.SetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 1,
                          colspan = 2,
                          level = 0,
                          levelspan = 1,
                          row = 0,
                          rowspan = 2
                        },
                        radioControlData = {
                          frequencyInteger = 99,
                          frequencyFraction = 3,
                          band = "FM",
                          rdsData = {
                            PS = "name",
                            RT = "radio",
                            CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                            PI = "Sign",
                            PTY = 1,
                            TP = true,
                            TA = true,
                            REG = "Murica"
                          },
                          availableHDs = 3,
                          hdChannel = 1,
                          signalStrength = 50,
                          signalChangeThreshold = 60,
                          radioEnable = true,
                          state = "ACQUIRING"
                        }
                      }
                  })

                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.3.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.3.2
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.11.3.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.3.3
      --Description: application sends SetInteriorVehicleData as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
        function Test:SetInterior_DriverAllowFrontRADIO_Time2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 0,
                rowspan = 2
              },
              radioControlData = {
                frequencyInteger = 99,
                frequencyFraction = 3,
                band = "FM",
                rdsData = {
                  PS = "name",
                  RT = "radio",
                  CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                  PI = "Sign",
                  PTY = 1,
                  TP = true,
                  TA = true,
                  REG = "Murica"
                },
                availableHDs = 3,
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
            }
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

              --hmi side: expect RC.SetInteriorVehicleData request
              EXPECT_HMICALL("RC.SetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.SetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 1,
                          colspan = 2,
                          level = 0,
                          levelspan = 1,
                          row = 0,
                          rowspan = 2
                        },
                        radioControlData = {
                          frequencyInteger = 99,
                          frequencyFraction = 3,
                          band = "FM",
                          rdsData = {
                            PS = "name",
                            RT = "radio",
                            CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                            PI = "Sign",
                            PTY = 1,
                            TP = true,
                            TA = true,
                            REG = "Murica"
                          },
                          availableHDs = 3,
                          hdChannel = 1,
                          signalStrength = 50,
                          signalChangeThreshold = 60,
                          radioEnable = true,
                          state = "ACQUIRING"
                        }
                      }
                  })

                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.3.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.3.4
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO
        function Test:SetInterior_DriverAllowLeftRADIO_Time1()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 0,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 1,
                rowspan = 2
              },
              radioControlData = {
                frequencyInteger = 99,
                frequencyFraction = 3,
                band = "FM"
              }
            }
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "RADIO",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.SetInteriorVehicleData request
              EXPECT_HMICALL("RC.SetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.SetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 0,
                          colspan = 2,
                          level = 0,
                          levelspan = 1,
                          row = 1,
                          rowspan = 2
                        },
                        radioControlData = {
                          frequencyInteger = 99,
                          frequencyFraction = 3,
                          band = "FM"
                        }
                      }
                  })

                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.3.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.3.5
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.11.3.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.3.6
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO
        function Test:SetInterior_DriverAllowLeftRADIO_Time2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 0,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 1,
                rowspan = 2
              },
              radioControlData = {
                frequencyInteger = 99,
                frequencyFraction = 3,
                band = "FM"
              }
            }
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "RADIO",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.SetInteriorVehicleData request
              EXPECT_HMICALL("RC.SetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.SetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 0,
                          colspan = 2,
                          level = 0,
                          levelspan = 1,
                          row = 1,
                          rowspan = 2
                        },
                        radioControlData = {
                          frequencyInteger = 99,
                          frequencyFraction = 3,
                          band = "FM"
                        }
                      }
                  })

                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.3.6

    -----------------------------------------------------------------------------------------


      --Begin Test case CommonRequestCheck.11.3.7
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE
        function Test:SetInterior_DriverAllowLeftCLIMATE_Time1()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                colspan = 2,
                row = 1,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0
              },
              climateControlData =
              {
                fanSpeed = 50,
                desiredTemp = 24,
                temperatureUnit = "CELSIUS"
              }
            }
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "CLIMATE",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.SetInteriorVehicleData request
              EXPECT_HMICALL("RC.SetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.SetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                    moduleData =
                    {
                      moduleType = "CLIMATE",
                      moduleZone =
                      {
                        colspan = 2,
                        row = 1,
                        rowspan = 2,
                        col = 0,
                        levelspan = 1,
                        level = 0
                      },
                      climateControlData =
                      {
                        fanSpeed = 50,
                        desiredTemp = 24,
                        temperatureUnit = "CELSIUS"
                      }
                    }
                  })

                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.3.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.3.8
      --Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
        function Test:EXIT_Application()

          --hmi side: HMI send BC.OnExitApplication to Rsdl.
          self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

          --mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.11.3.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.11.3.9
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE
        function Test:SetInterior_DriverAllowLeftCLIMATE_Time2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                colspan = 2,
                row = 1,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0
              },
              climateControlData =
              {
                fanSpeed = 50,
                desiredTemp = 24,
                temperatureUnit = "CELSIUS"
              }
            }
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "CLIMATE",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
                })
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.SetInteriorVehicleData request
              EXPECT_HMICALL("RC.SetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.SetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                    moduleData =
                    {
                      moduleType = "CLIMATE",
                      moduleZone =
                      {
                        colspan = 2,
                        row = 1,
                        rowspan = 2,
                        col = 0,
                        levelspan = 1,
                        level = 0
                      },
                      climateControlData =
                      {
                        fanSpeed = 50,
                        desiredTemp = 24,
                        temperatureUnit = "CELSIUS"
                      }
                    }
                  })

                end)
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.11.3.9

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.11.3

--=================================================END TEST CASES 11==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end