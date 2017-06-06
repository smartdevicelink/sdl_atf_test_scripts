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

---------------------------------------------------------------------------------------------
-----------------------Requirement: HMI's RPCs validation rules------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
  --Begin Test suit CommonRequestCheck

  --Description: RSDL must validate each and every RPC (that is, responses and notifications) that HMI sends per "Remote-Control-API" ([attached|^SDL_RC_HMI_API_from_Ford_v2.xml]).
    -- Invalid response expected by mobile app
    -- Invalid response expected by RSDL
    -- Invalid notification
    -- Fake params

--=================================================BEGIN TEST CASES 10==========================================================--

  --Begin Test case ResponseMissingCheckNotification.10
  --Description:  --Invalid notification

    --Requirement/Diagrams id in jira:
        --Requirement

    ---------------------------------------------------------------------------------------------
    -------------------------------------------Preconditions-------------------------------------
    ---------------------------------------------------------------------------------------------

      --Begin Test case Precondition.1
      --Description: mobile sends GetInteriorVehicleData request with subscribe = true for precondtion
        function Test:OnInteriorVehicleData_Precondition_RADIO()
          --mobile sends request for precondition
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
                col = 0,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: expect RC.GetInteriorVehicleData request
          EXPECT_HMICALL("RC.GetInteriorVehicleData")
          :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
                  moduleData = {
                    moduleType = "RADIO",
                    moduleZone = {
                      col = 0,
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

            --mobile side: expect SUCCESS response
            EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

        end
      --End Test case Precondition.1

      --Begin Test case Precondition.2
      --Description: GetInteriorVehicleData response with subscribe = true for precondtion
        function Test:GetInteriorVehicleData_Precondition_CLIMATE()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: expect RC.GetInteriorVehicleData request
          EXPECT_HMICALL("RC.GetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.GetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
                moduleData =
                {
                  moduleType = "CLIMATE",
                  moduleZone =
                  {
                    colspan = 2,
                    row = 0,
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

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

        end
      --End Test case Precondition.2

    ---------------------------------------------------------------------------------------------
    -------------------------------------------Preconditions-------------------------------------
    ---------------------------------------------------------------------------------------------

    --Verification criteria:
        --<11.>In case HMI sends a notification with one or more of mandatory per rc-HMI_API params missing to RSDL, RSDL must log an error and ignore this notification.

      --Begin Test case ResponseMissingCheckNotification.10.1
      --Description: send notification with all params missing
        function Test:OnInteriorVehicleData_MissingAllParams()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {})

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.1

    -----------------------------------------------------------------------------------------


      --Begin Test case ResponseMissingCheckNotification.10.2
      --Description: send notification with moduleType missing
        function Test:OnInteriorVehicleData_MissingModuleType()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.3
      --Description: send notification with moduleZone missing
        function Test:OnInteriorVehicleData_MissingModuleZone()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.4
      --Description: send notification with col missing
        function Test:OnInteriorVehicleData_MissingCol()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.5
      --Description: send notification with row missing
        function Test:OnInteriorVehicleData_MissingRow()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.5

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.6
      --Description: send notification with level missing
        function Test:OnInteriorVehicleData_MissingLevel()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.6

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.7
      --Description: send notification with colspan missing
        function Test:OnInteriorVehicleData_MissingColspan()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.7

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.8
      --Description: send notification with rowspan missing
        function Test:OnInteriorVehicleData_MissingRowspan()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.8

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.9
      --Description: send notification with levelspan missing
        function Test:OnInteriorVehicleData_MissingLevelspan()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.9

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.10
      --Description: send notification with climateControlData missing
        function Test:OnInteriorVehicleData_MissingClimateControlData()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.10

    -----------------------------------------------------------------------------------------


      --Begin Test case ResponseMissingCheckNotification.10.11
      --Description: send notification with fanSpeed missing
        function Test:OnInteriorVehicleData_MissingFanSpeed()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.11

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.12
      --Description: send notification with currentTemp missing
        function Test:OnInteriorVehicleData_MissingCurrentTemp()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.12

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.13
      --Description: send notification with desiredTemp missing
        function Test:OnInteriorVehicleData_MissingDesiredTemp()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.14
      --Description: send notification with temperatureUnit missing
        function Test:OnInteriorVehicleData_MissingTemperatureUnit()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.15
      --Description: send notification with acEnable missing
        function Test:OnInteriorVehicleData_MissingAcEnable()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.15

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.16
      --Description: send notification with circulateAirEnable missing
        function Test:OnInteriorVehicleData_MissingCirculateAirEnable()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.16

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.17
      --Description: send notification with autoModeEnable missing
        function Test:OnInteriorVehicleData_MissingAutoModeEnable()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      defrostZone = "FRONT",
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.17

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.18
      --Description: send notification with defrostZone missing
        function Test:OnInteriorVehicleData_MissingDefrostZone()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      dualModeEnable = true
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.18

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.19
      --Description: send notification with dualModeEnable missing
        function Test:OnInteriorVehicleData_MissingDualModeEnable()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                moduleData = {
                    moduleType = "CLIMATE",
                    moduleZone = {
                      col = 0,
                      row = 0,
                      level = 0,
                      colspan = 2,
                      rowspan = 2,
                      levelspan = 1
                    },
                    climateControlData = {
                      fanSpeed = 50,
                      currentTemp = 86,
                      desiredTemp = 75,
                      temperatureUnit = "FAHRENHEIT",
                      acEnable = true,
                      circulateAirEnable = true,
                      autoModeEnable = true,
                      defrostZone = "FRONT"
                    }
                  }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.19

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.20
      --Description: send notification with radioControlData missing
        function Test:OnInteriorVehicleData_MissingRadioControlData()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.20

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.21
      --Description: send notification with radioEnable missing
        function Test:OnInteriorVehicleData_MissingRadioEnable()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.21

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.22
      --Description: send notification with frequencyInteger missing
        function Test:OnInteriorVehicleData_MissingFrequencyInteger()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.22

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.23
      --Description: send notification with frequencyFraction missing
        function Test:OnInteriorVehicleData_MissingFrequencyFraction()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)

        end
      --End Test case ResponseMissingCheckNotification.10.23

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.24
      --Description: send notification with band missing
        function Test:OnInteriorVehicleData_MissingBand()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.24

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.25
      --Description: send notification with hdChannel missing
        function Test:OnInteriorVehicleData_MissinghdChannel()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.25

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.26
      --Description: send notification with state missing
        function Test:OnInteriorVehicleData_MissingState()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.26

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.27
      --Description: send notification with availableHDs missing
        function Test:OnInteriorVehicleData_MissingAvailableHDs()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.27

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.28
      --Description: send notification with signalStrength missing
        function Test:OnInteriorVehicleData_MissingSignalStrength()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.28

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.29
      --Description: send notification with rdsData missing
        function Test:OnInteriorVehicleData_MissingRdsData()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.29

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.30
      --Description: send notification with PS missing
        function Test:OnInteriorVehicleData_MissingPS()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.30

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.31
      --Description: send notification with RT missing
        function Test:OnInteriorVehicleData_MissingRT()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.31

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.32
      --Description: send notification with CT missing
        function Test:OnInteriorVehicleData_MissingCT()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.32

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.33
      --Description: send notification with PI missing
        function Test:OnInteriorVehicleData_MissingPI()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.33

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.34
      --Description: send notification with PTY missing
        function Test:OnInteriorVehicleData_MissingPTY()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            TP = true,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.34

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.35
      --Description: send notification with TP missing
        function Test:OnInteriorVehicleData_MissingTP()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TA = false,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.35

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.36
      --Description: send notification with TA missing
        function Test:OnInteriorVehicleData_MissingTA()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            REG = ""
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.36

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.37
      --Description: send notification with REG missing
        function Test:OnInteriorVehicleData_MissingREG()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false
                          },
                          signalChangeThreshold = 10
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseMissingCheckNotification.10.37

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.38
      --Description: send notification with signalChangeThreshold missing
        function Test:OnInteriorVehicleData_MissingsignalChangeThreshold()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          hdChannel = 1,
                          state = "ACQUIRED",
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = ""
                          }
                        },
                        moduleType = "RADIO",
                        moduleZone =
                        {
                          colspan = 2,
                          row = 0,
                          rowspan = 2,
                          col = 0,
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)


        end
      --End Test case ResponseMissingCheckNotification.10.38

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.39
      --Description: send notification with all params missing
        function Test:OnSetDriversDevice_MissingAllParams()

          --hmi side: sending RC.OnSetDriversDevice notification
          self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {})

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseMissingCheckNotification.10.39

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.40
      --Description: send notification with name missing
        function Test:OnSetDriversDevice_MissingName()

          --hmi side: sending RC.OnSetDriversDevice notification
          self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {
                  device = {
                    id = 1,
                    isSDLAllowed = true
                  }
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseMissingCheckNotification.10.40

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.41
      --Description: send notification with ID missing
        function Test:OnSetDriversDevice_MissingID()

          --hmi side: sending RC.OnSetDriversDevice notification
          self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {
                  device = {
                    name = "127.0.0.1",
                    isSDLAllowed = true
                  }
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseMissingCheckNotification.10.41

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheckNotification.10.42
      --Description: send notification with allowed missing
        function Test:OnReverseAppsAllowing_MissingAllowed()

          --hmi side: sending VehicleInfo.OnReverseAppsAllowing notification
          self.hmiConnection:SendNotification("VehicleInfo.OnReverseAppsAllowing", {
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseMissingCheckNotification.10.42

  --End Test case ResponseMissingCheckNotification.10
--=================================================END TEST CASES 10==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end