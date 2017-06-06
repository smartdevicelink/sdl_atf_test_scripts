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
-----------Requirement: "Allow", "Ask Driver" or "Disallow" permissions - depending-----------
------------------on zone value in RPC and this zone permissions in Policies-----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--
--=================================================BEGIN TEST CASES 5==========================================================--

  --Begin Test case CommonRequestCheck.5.6
  --Description:  For SetInteriorVehicleData

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement, Requirement

    --Verification criteria:
        --In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.5.
      --Description: Register new session
        function Test:PreconditionNewSession()
          --New session1
          self.mobileSession1 = mobile_session.MobileSession(
            self,
            self.mobileConnection)
        end
      --End Test case Precondition.5.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.5.
      --Description: Register App1 for precondition
          function Test:TC1_PassengerDevice_App1()
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

                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"},
                  { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER"})
                :Times(2):Timeout(3000)

              end)
            end
      --End Test case Precondition.5.
    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.1
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO (first time, asking driver's permission)
        function Test:SetInterior_App1LeftRADIO_1()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
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

          self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.6.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.2
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE (first time, asking driver's permission)
        function Test:SetInterior_App2LeftCLIMATE_2()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData",
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
                  appID = self.applications["Test Application1"],
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

          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.6.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.3
      --Description: application sends ButtonPress as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE in the second time (doesn't ask driver's permission)
        function Test:ButtonPress_App2LeftCLIMATE_3()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("ButtonPress",
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

          --hmi side: expect RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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

          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.6.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.4
      --Description: application sends ButtonPress as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE in the third time doesn't ask driver's permission)
        function Test:ButtonPress_DifferentAppLeftCLIMATE_4()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("ButtonPress",
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
            buttonPressMode = "LONG",
            buttonName = "DEFROST_MAX"
          })

          --hmi side: expect RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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
                    buttonPressMode = "LONG",
                    buttonName = "DEFROST_MAX"
                  })
            :Do(function(_,data)
              --hmi side: sending Buttons.ButtonPress response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            end)

          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.6.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.5
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE in the second time(doesn't ask driver's permission)
        function Test:GetInterior_DifferentAppLeftCLIMATE_5()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData",
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

          --hmi side: expect RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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

          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.6.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.6
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE in the third time (doesn't ask driver's permission)
        function Test:GetInterior_DifferentAppLeftCLIMATE_6()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData",
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
            subscribe = false
          })

          --hmi side: expect RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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

          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.6.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.7
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE in the second time (doesn't ask driver's permission)
        function Test:SetInterior_DifferentAppLeftCLIMATE_7()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData",
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

          --hmi side: expect doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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

          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.6.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.8
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE in the third time (doesn't ask driver's permission)
        function Test:SetInterior_DifferentAppLeftCLIMATE_8()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData",
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
                fanSpeed = 49,
                desiredTemp = 24,
                temperatureUnit = "CELSIUS"
              }
            }
          })

          --hmi side: expect doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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
                    fanSpeed = 49,
                    desiredTemp = 24,
                    temperatureUnit = "CELSIUS"
                  }
                }
              })

          end)

          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.6.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.9
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO in the second time(doesn't ask driver's permission)
        function Test:GetInterior_DifferentAppLeftRADIO_9()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData",
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

          --hmi side: expect RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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
            --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL and HMI auto reject this request.
            self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"error":{"code":4,"message":"Already consented!","data":{"method":"RC.GetInteriorVehicleDataConsent"}}}')
          end)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false
          self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "USER_DISALLOWED" })
        end
      --End Test case CommonRequestCheck.5.6.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.10
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO in the third time(doesn't ask driver's permission)
        function Test:GetInterior_DifferentAppLeftRADIO_10()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData",
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
            subscribe = false
          })

          --hmi side: expect RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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
            --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL and HMI auto reject this request.
            self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"error":{"code":4,"message":"Already consented!","data":{"method":"RC.GetInteriorVehicleDataConsent"}}}')
          end)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false
          self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "USER_DISALLOWED" })
        end
      --End Test case CommonRequestCheck.5.6.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.11
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO in the second time(doesn't ask driver's permission)
        function Test:SetInterior_DifferentAppLeftRADIO_11()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData",
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

          --hmi side: expect RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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
            --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL and HMI auto reject this request.
            self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"error":{"code":4,"message":"Already consented!","data":{"method":"RC.GetInteriorVehicleDataConsent"}}}')
          end)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false
          self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "USER_DISALLOWED" })
        end
      --End Test case CommonRequestCheck.5.6.11

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6.12
      --Description: application sends SetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO in the third time(doesn't ask driver's permission)
        function Test:SetInterior_DifferentAppLeftRADIO_12()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section and the vehicle (HMI) responds with "allowed: true" for RSDL's RC.GetInteriorVehicleDataConsent - RSDL must send this (app's initial) RPC with these <params> to the vehicle (HMI).
          local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData",
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
                frequencyInteger = 95,
                frequencyFraction = 3,
                band = "AM"
              }
            }
          })

          --hmi side: expect RSDL doesn't send RC.GetInteriorVehicleDataConsent request to HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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
            --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL and HMI auto reject this request.
            self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"error":{"code":4,"message":"Already consented!","data":{"method":"RC.GetInteriorVehicleDataConsent"}}}')
          end)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false
          self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "USER_DISALLOWED" })
        end
      --End Test case CommonRequestCheck.5.6.12
    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.5.6

--=================================================END TEST CASES 5==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
