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

--=================================================BEGIN TEST CASES 11==========================================================--


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


      --Begin Test case ResponseOutOfBoundNotification.11
      --Description:  --Invalid notification

        --Requirement/Diagrams id in jira:
            --Requirement

        --Verification criteria:
            --<12.>In case HMI sends a notification with one or more of out-of-bounds per rc-HMI_API values to RSDL, RSDL must log an error and ignore this notification.

      --Begin Test case ResponseOutOfBoundNotification.11.1
      --Description: OnInteriorVehicleData with all parameters out of bounds
        function Test:OnInteriorVehicleData_AllParamsOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  moduleType = "CLIMATE",
                  moduleZone =
                  {
                    colspan = -1,
                    row = -1,
                    rowspan = -1,
                    col = -1,
                    levelspan = -1,
                    level = -1
                  },
                  climateControlData =
                  {
                    fanSpeed = -1,
                    circulateAirEnable = true,
                    dualModeEnable = true,
                    currentTemp = -1,
                    defrostZone = "FRONT",
                    acEnable = true,
                    desiredTemp = -1,
                    autoModeEnable = true,
                    temperatureUnit = "CELSIUS"
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.2
      --Description: OnInteriorVehicleData with Colspan parameter out of bounds
        function Test:OnInteriorVehicleData_ColspanOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  moduleType = "CLIMATE",
                  moduleZone =
                  {
                    colspan = -1,
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

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.3
      --Description: OnInteriorVehicleData with row parameter out of bounds
        function Test:OnInteriorVehicleData_RowOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  moduleType = "CLIMATE",
                  moduleZone =
                  {
                    colspan = 2,
                    row = -1,
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

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.4
      --Description: OnInteriorVehicleData with rowspan parameter out of bounds
        function Test:OnInteriorVehicleData_RowspanOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  moduleType = "CLIMATE",
                  moduleZone =
                  {
                    colspan = 2,
                    row = 0,
                    rowspan = -1,
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

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.5
      --Description: OnInteriorVehicleData with col parameter out of bounds
        function Test:OnInteriorVehicleData_ColOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  moduleType = "CLIMATE",
                  moduleZone =
                  {
                    colspan = 2,
                    row = 0,
                    rowspan = 2,
                    col = -1,
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

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.5

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.6
      --Description: OnInteriorVehicleData with levelspan parameter out of bounds
        function Test:OnInteriorVehicleData_LevelspanOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  moduleType = "CLIMATE",
                  moduleZone =
                  {
                    colspan = 2,
                    row = 0,
                    rowspan = 2,
                    col = 0,
                    levelspan = -1,
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

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.6

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.7
      --Description: OnInteriorVehicleData with level parameter out of bounds
        function Test:OnInteriorVehicleData_LevelOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    level = -1
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

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.7

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.8
      --Description: OnInteriorVehicleData with frequencyInteger parameter out of bounds
        function Test:OnInteriorVehicleData_FrequencyIntegerOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  radioControlData =
                  {
                    radioEnable = true,
                    frequencyInteger = -1,
                    frequencyFraction = 3,
                    band = "AM",
                    hdChannel = 1,
                    state = "ACQUIRED",
                    availableHDs = 1,
                    signalStrength = 50,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.8

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.9
      --Description: OnInteriorVehicleData with frequencyFraction parameter out of bounds
        function Test:OnInteriorVehicleData_FrequencyFractionOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  radioControlData =
                  {
                    radioEnable = true,
                    frequencyInteger = 105,
                    frequencyFraction = -1,
                    band = "AM",
                    hdChannel = 1,
                    state = "ACQUIRED",
                    availableHDs = 1,
                    signalStrength = 50,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.9

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.10
      --Description: OnInteriorVehicleData with hdChannel parameter out of bounds
        function Test:OnInteriorVehicleData_HdChannelOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  radioControlData =
                  {
                    radioEnable = true,
                    frequencyInteger = 105,
                    frequencyFraction = 3,
                    band = "AM",
                    hdChannel = 0,
                    state = "ACQUIRED",
                    availableHDs = 1,
                    signalStrength = 50,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.10

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.11
      --Description: OnInteriorVehicleData with availableHDs parameter out of bounds
        function Test:OnInteriorVehicleData_AvailableHDsOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    availableHDs = 0,
                    signalStrength = 50,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.11

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.12
      --Description: OnInteriorVehicleData with signalStrength parameter out of bounds
        function Test:OnInteriorVehicleData_SignalStrengthOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    signalStrength = -1,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.12

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.13
      --Description: OnInteriorVehicleData with signalChangeThreshold parameter out of bounds
        function Test:OnInteriorVehicleData_SignalChangeThresholdOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
                    },
                    signalChangeThreshold = -1
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
      --End Test case ResponseOutOfBoundNotification.11.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.14
      --Description: OnInteriorVehicleData with fanSpeed parameter out of bounds
        function Test:OnInteriorVehicleData_FanSpeedOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    fanSpeed = -1,
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

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.15
      --Description: OnInteriorVehicleData with currentTemp parameter out of bounds
        function Test:OnInteriorVehicleData_CurrentTempOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    currentTemp = -1,
                    defrostZone = "FRONT",
                    acEnable = true,
                    desiredTemp = 24,
                    autoModeEnable = true,
                    temperatureUnit = "CELSIUS"
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.15

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.16
      --Description: OnInteriorVehicleData with desiredTemp parameter out of bounds
        function Test:OnInteriorVehicleData_DesiredTempOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    desiredTemp = -1,
                    autoModeEnable = true,
                    temperatureUnit = "CELSIUS"
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.16

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.17
      --Description: OnInteriorVehicleData with all parameters out of bounds
        function Test:OnInteriorVehicleData_AllParamsOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  moduleType = "CLIMATE",
                  moduleZone =
                  {
                    colspan = 101,
                    row = 101,
                    rowspan = 101,
                    col = 101,
                    levelspan = 101,
                    level = 101
                  },
                  climateControlData =
                  {
                    fanSpeed = 101,
                    circulateAirEnable = true,
                    dualModeEnable = true,
                    currentTemp = 101,
                    defrostZone = "FRONT",
                    acEnable = true,
                    desiredTemp = 101,
                    autoModeEnable = true,
                    temperatureUnit = "CELSIUS"
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.17

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.18
      --Description: OnInteriorVehicleData with Colspan parameter out of bounds
        function Test:OnInteriorVehicleData_ColspanOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
                    },
                    signalChangeThreshold = 10
                  },
                  moduleType = "RADIO",
                  moduleZone =
                  {
                    colspan = 101,
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
      --End Test case ResponseOutOfBoundNotification.11.18

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.19
      --Description: OnInteriorVehicleData with row parameter out of bounds
        function Test:OnInteriorVehicleData_RowOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
                    },
                    signalChangeThreshold = 10
                  },
                  moduleType = "RADIO",
                  moduleZone =
                  {
                    colspan = 2,
                    row = 101,
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
      --End Test case ResponseOutOfBoundNotification.11.19

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.20
      --Description: OnInteriorVehicleData with rowspan parameter out of bounds
        function Test:OnInteriorVehicleData_RowspanOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
                    },
                    signalChangeThreshold = 10
                  },
                  moduleType = "RADIO",
                  moduleZone =
                  {
                    colspan = 2,
                    row = 0,
                    rowspan = 101,
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
      --End Test case ResponseOutOfBoundNotification.11.20

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.21
      --Description: OnInteriorVehicleData with col parameter out of bounds
        function Test:OnInteriorVehicleData_ColOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
                    },
                    signalChangeThreshold = 10
                  },
                  moduleType = "RADIO",
                  moduleZone =
                  {
                    colspan = 2,
                    row = 0,
                    rowspan = 2,
                    col = 101,
                    levelspan = 1,
                    level = 0
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.21

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.22
      --Description: OnInteriorVehicleData with levelspan parameter out of bounds
        function Test:OnInteriorVehicleData_LevelspanOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
                    levelspan = 101,
                    level = 0
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.22

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.23
      --Description: OnInteriorVehicleData with level parameter out of bounds
        function Test:OnInteriorVehicleData_levelOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
                    level = 101
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.23

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.24
      --Description: OnInteriorVehicleData with frequencyInteger parameter out of bounds
        function Test:OnInteriorVehicleData_FrequencyIntegerOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  radioControlData =
                  {
                    radioEnable = true,
                    frequencyInteger = 1711,
                    frequencyFraction = 3,
                    band = "AM",
                    hdChannel = 1,
                    state = "ACQUIRED",
                    availableHDs = 1,
                    signalStrength = 50,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.24

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.25
      --Description: OnInteriorVehicleData with frequencyFraction parameter out of bounds
        function Test:OnInteriorVehicleData_FrequencyFractionOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  radioControlData =
                  {
                    radioEnable = true,
                    frequencyInteger = 105,
                    frequencyFraction = 10,
                    band = "AM",
                    hdChannel = 1,
                    state = "ACQUIRED",
                    availableHDs = 1,
                    signalStrength = 50,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.25

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.26
      --Description: OnInteriorVehicleData with hdChannel parameter out of bounds
        function Test:OnInteriorVehicleData_HdChannelOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  radioControlData =
                  {
                    radioEnable = true,
                    frequencyInteger = 105,
                    frequencyFraction = 3,
                    band = "AM",
                    hdChannel = 4,
                    state = "ACQUIRED",
                    availableHDs = 1,
                    signalStrength = 50,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.26

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.27
      --Description: OnInteriorVehicleData with availableHDs parameter out of bounds
        function Test:OnInteriorVehicleData_AvailableHDsOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    availableHDs = 4,
                    signalStrength = 50,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.27

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.28
      --Description: OnInteriorVehicleData with signalStrength parameter out of bounds
        function Test:OnInteriorVehicleData_SignalStrengthOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    signalStrength = 101,
                    rdsData =
                    {
                      PS = "12345678",
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.28

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.29
      --Description: OnInteriorVehicleData with signalChangeThreshold parameter out of bounds
        function Test:OnInteriorVehicleData_SignalChangeThresholdOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
                    },
                    signalChangeThreshold = 101
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
      --End Test case ResponseOutOfBoundNotification.11.29

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.30
      --Description: OnInteriorVehicleData with fanSpeed parameter out of bounds
        function Test:OnInteriorVehicleData_FanSpeedOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    fanSpeed = 101,
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

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.30

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.31
      --Description: OnInteriorVehicleData with currentTemp parameter out of bounds
        function Test:OnInteriorVehicleData_CurrentTempOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    currentTemp = 101,
                    defrostZone = "FRONT",
                    acEnable = true,
                    desiredTemp = 24,
                    autoModeEnable = true,
                    temperatureUnit = "CELSIUS"
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.31

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.32
      --Description: OnInteriorVehicleData with desiredTemp parameter out of bounds
        function Test:OnInteriorVehicleData_DesiredTempOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                    desiredTemp = 101,
                    autoModeEnable = true,
                    temperatureUnit = "CELSIUS"
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.32

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.33
      --Description: OnInteriorVehicleData with CT parameter out of bounds
        function Test:OnInteriorVehicleData_CTOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-070",
                      PI = "PIdent",
                      PTY = 0,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
                    },
                    signalChangeThreshold = 10
                  },
                  moduleType = "RADIO",
                  moduleZone =
                  {
                    clospan = 1,
                    row = 1,
                    rowspan = 1,
                    col = 1,
                    levelspan = 1,
                    level = 1
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.33

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.34
      --Description: OnInteriorVehicleData with PTY parameter out of bounds
        function Test:OnInteriorVehicleData_PTYOutLowerBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                      RT = "Radio text minlength = 0, maxlength = 64",
                      CT = "2015-09-29T18:46:19-0700",
                      PI = "PIdent",
                      PTY = -1,
                      TP = true,
                      TA = false,
                      REG = "don't mention min,max length"
                    },
                    signalChangeThreshold = 10
                  },
                  moduleType = "RADIO",
                  moduleZone =
                  {
                    clospan = 1,
                    row = 1,
                    rowspan = 1,
                    col = 1,
                    levelspan = 1,
                    level = 1
                  }
                }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseOutOfBoundNotification.11.34

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.35
      --Description: OnInteriorVehicleData with PS parameter out of bounds
        function Test:OnInteriorVehicleData_PSOutUpperBound()

          --hmi side: sending RC.OnInteriorVehicleData notification
          self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
          {
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
                  PS = "123456789",
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdent",
                  PTY = 0,
                  TP = true,
                  TA = false,
                  REG = "don't mention min,max length"
                },
                signalChangeThreshold = 10
              },
              moduleType = "RADIO",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            }
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnInteriorVehicleData")
          :Times(0)

        end
      --End Test case ResponseOutOfBoundNotification.11.35

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.36
      --Description: OnInteriorVehicleData with PI parameter out of bounds
        function Test:OnInteriorVehicleData_PIOutUpperBound()

          --hmi side: sending RC.OnInteriorVehicleData notification
          self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
          {
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdentI",
                  PTY = 0,
                  TP = true,
                  TA = false,
                  REG = "don't mention min,max length"
                },
                signalChangeThreshold = 10
              },
              moduleType = "RADIO",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            }
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnInteriorVehicleData")
          :Times(0)

        end
      --End Test case ResponseOutOfBoundNotification.11.36

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.37
      --Description: OnInteriorVehicleData with RT parameter out of bounds
        function Test:OnInteriorVehicleData_RTOutUpperBound()

          --hmi side: sending RC.OnInteriorVehicleData notification
          self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
          {
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
                        RT = "RADIO TEXT Minlength = 0, Maxlength = 64 RADIO TEXT Minlength = 6",
                        CT = "2015-09-29T18:46:19-0700",
                        PI = "PIdent",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.37

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundNotification.11.38
      --Description: OnInteriorVehicleData with CT parameter out of bounds
        function Test:OnInteriorVehicleData_CTOutUpperBound()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
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
                            RT = "Radio text minlength = 0, maxlength = 64",
                            CT = "2015-09-29T18:46:19-07009",
                            PI = "PIdent",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = "don't mention min,max length"
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
      --End Test case ResponseOutOfBoundNotification.11.38

    --End Test case ResponseOutOfBoundNotification.11
--=================================================END TEST CASES 11==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end