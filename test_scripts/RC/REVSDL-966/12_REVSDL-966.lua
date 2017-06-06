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

--=================================================BEGIN TEST CASES 12==========================================================--
  --Begin Test suit CommonRequestCheck.12 for Req.#12

  --Description: 12. In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database omits this RPC name with <params> in <moduleType> of both "auto_allow" and "driver_allow" sub-sections of <interiorZone> section - RSDL must respond with "resultCode: DISALLOWED, success: false, info: "The RPC is disallowed by vehicle settings" to this application (that is, without asking a driver for permission).


  --Begin Test case CommonRequestCheck.12.1
  --Description:  In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database omits this RPC name with <params> in <moduleType> of both "auto_allow" and "driver_allow" sub-sections of <interiorZone> section - RSDL must respond with "resultCode: DISALLOWED, success: false, info: "The RPC is disallowed by vehicle settings" to this application (that is, without asking a driver for permission).

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case RPC_1 is omitted in both "auto_allow" and "driver_allow" sections.
        --RSDL must respond with "resultCode: DISALLOWED, success: false, info: "The RPC is disallowed by vehicle settings" to this application (that is, without asking a driver for permission).

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.12.1.1
      --Description: application sends ButtonPress as Right Rare Passenger (col=1, row=1, level=0) and ModuleType = CLIMATE (DISALLOWED)
        function Test:ButtonPress_CLIMATE_DISALLOWED()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 2,
              row = 1,
              rowspan = 2,
              col = 1,
              levelspan = 1,
              level = 0
            },
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "LOWER_VENT"
          })

          --hmi side: RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
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
          :Times(0)


          --RSDL must respond with "resultCode: DISALLOWED, success: false, info: "The RPC is disallowed by vehicle settings" to this application
          EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
        end
      --End Test case CommonRequestCheck.12.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.12.1.2
      --Description: application sends GetInteriorVehicleData as Right Rare Passenger (col=1, row=1, level=0) and ModuleType = CLIMATE (DISALLOWED)
        function Test:GetInterior_CLIMATE_DISALLOWED()
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
                col = 1,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: --hmi side: RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
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
          :Times(0)


          --RSDL must respond with "resultCode: DISALLOWED, success: false, info: "The RPC is disallowed by vehicle settings" to this application
          EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
        end
      --End Test case CommonRequestCheck.12.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.12.1.3
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO (DISSALLOWED)
        function Test:SetInterior_LeftRADIO_DISSALLOWED()
          --mobile side: In case the application sends all invalid rc-RPCs with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid1 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
          local cid2 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                band = "FM",
                availableHDs = 3,
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
            }
          })
          local cid3 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                band = "FM",
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
            }
          })
          local cid4 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                hdChannel = 1,
                state = "ACQUIRING"
              }
            }
            })
          local cid5 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                band = "FM",
                signalChangeThreshold = 60,
                radioEnable = true,
                hdChannel = 1,
                state = "ACQUIRING"
              }
            }
          })
          local cid6 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                radioEnable = true,
                hdChannel = 1,
                state = "ACQUIRING"
              }
            }
            })
          local cid7 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                band = "FM",
                hdChannel = 1,
                state = "ACQUIRING"
              }
            }
          })
          local cid8 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                hdChannel = 1,
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
                }
              }
            }
          })
          local cid9 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                hdChannel = 1,
                rdsData = {
                  PS = "name",
                  RT = "radio",
                  CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                  PI = "Sign",
                  PTY = 1,
                  TP = true,
                  TA = true,
                  REG = "Murica"
                }
              }
            }
          })
          local cid10 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                band = "FM",
                hdChannel = 1,
                rdsData = {
                  PS = "name",
                  RT = "radio",
                  CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                  PI = "Sign",
                  PTY = 1,
                  TP = true,
                  TA = true,
                  REG = "Murica"
                }
              }
            }
          })


          --hmi side: RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
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
          :Times(0)


          --RSDL must respond with "resultCode: DISALLOWED, success: false, info: "The RPC is disallowed by vehicle settings" to this application
          EXPECT_RESPONSE(cid1, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid2, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid3, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid4, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid5, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid6, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid7, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid8, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid9, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid10, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
        end
      --End Test case CommonRequestCheck.12.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.12.1.4
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE (DISSALLOWED)
        function Test:SetInterior_LeftCLIMATE_DISSALLOWED()
          --mobile side: In case the application sends all invalid rc-RPCs with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid1 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
          local cid2 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
          local cid3 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                currentTemp = 30,
                defrostZone = "FRONT",
                acEnable = true,
                desiredTemp = 24,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
          })
          local cid4 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                defrostZone = "FRONT",
                acEnable = true,
                desiredTemp = 24,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
          })
          local cid5 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                acEnable = true,
                desiredTemp = 24,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
          })
          local cid6 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
          })
          local cid7 = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                desiredTemp = 24,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
          })

          --hmi side: RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
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
          :Times(0)

          --RSDL must respond with "resultCode: DISALLOWED, success: false, info: "The RPC is disallowed by vehicle settings" to this application
          EXPECT_RESPONSE(cid1, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid2, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid3, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid4, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid5, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid6, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid7, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
        end
      --End Test case CommonRequestCheck.12.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.12.1.5
      --Description: application sends SetInteriorVehicleData as Right Rare Passenger (col=1, row=1, level=0) and ModuleType = RADIO (DISSALLOWED)
        function Test:SetInterior_RightRADIO_DISSALLOWED()
          --mobile side: In case the application sends all invalid rc-RPCs with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid1 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
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
          local cid2 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
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
                availableHDs = 3,
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
            }
          })
          local cid3 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
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
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
            }
          })
          local cid4 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 1,
                rowspan = 2
              },
              radioControlData = {
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                hdChannel = 1,
                state = "ACQUIRING"
              }
            }
            })
          local cid5 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
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
                signalChangeThreshold = 60,
                radioEnable = true,
                hdChannel = 1,
                state = "ACQUIRING"
              }
            }
          })
          local cid6 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 1,
                rowspan = 2
              },
              radioControlData = {
                radioEnable = true,
                hdChannel = 1,
                state = "ACQUIRING"
              }
            }
            })
          local cid7 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
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
                hdChannel = 1,
                state = "ACQUIRING"
              }
            }
          })
          local cid8 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 1,
                rowspan = 2
              },
              radioControlData = {
                frequencyInteger = 99,
                frequencyFraction = 3,
                hdChannel = 1,
                band = "FM"
              }
            }
          })
          local cid9 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 1,
                rowspan = 2
              },
              radioControlData = {
                frequencyInteger = 99,
                hdChannel = 1,
                rdsData = {
                  PS = "name",
                  RT = "radio",
                  CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                  PI = "Sign",
                  PTY = 1,
                  TP = true,
                  TA = true,
                  REG = "Murica"
                }
              }
            }
          })
          local cid10 = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 1,
                rowspan = 2
              },

              radioControlData = {
                frequencyInteger = 99,
                hdChannel = 1,
                band = "FM"
                }
              }
            })


          --hmi side: RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "RADIO",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 1,
                    levelspan = 1,
                    level = 0
                  }
          })
          :Times(0)


          --RSDL must respond with "resultCode: DISALLOWED, success: false, info: "The RPC is disallowed by vehicle settings" to this application
          EXPECT_RESPONSE(cid1, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid2, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid3, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid4, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid5, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid6, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid7, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid8, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid9, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
          EXPECT_RESPONSE(cid10, { success = false, resultCode = "DISALLOWED", info = "The RPC is disallowed by vehicle settings" })
        end
      --End Test case CommonRequestCheck.12.1.5

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.12.1

--=================================================END TEST CASES 12==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end