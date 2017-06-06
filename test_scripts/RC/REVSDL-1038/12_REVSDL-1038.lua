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

--=================================================BEGIN TEST CASES 12==========================================================--

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


      --Begin Test case ResponseWrongTypeNotification.12
      --Description:  --Invalid notification

        --Requirement/Diagrams id in jira:
            --Requirement

        --Verification criteria:
            --<13.>In case HMI sends a notification with one or more params of wrong type per rc-HMI_API to RSDL, RSDL must log an error and ignore this notification.

      --Begin Test case ResponseWrongTypeNotification.12.1
      --Description: OnInteriorVehicleData with all parameters of wrong type
        function Test:OnInteriorVehicleData_AllParamsWrongType()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = "true",
                          frequencyInteger = "105",
                          frequencyFraction = "3",
                          band = true,
                          hdChannel = "1",
                          state = 123,
                          availableHDs = "1",
                          signalStrength = "50",
                          rdsData =
                          {
                            PS = 12345678,
                            RT = false,
                            CT = 123456789123456789123456,
                            PI = true,
                            PTY = "0",
                            TP = "true",
                            TA = "false",
                            REG = 123
                          },
                          signalChangeThreshold = "10"
                        },
                        moduleType = true,
                        moduleZone =
                        {
                          colspan = "2",
                          row = "0",
                          rowspan = "2",
                          col = "0",
                          levelspan = "1",
                          level = "0"
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.1

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.2
      --Description: OnInteriorVehicleData with radioEnable parameter of wrong type
        function Test:OnInteriorVehicleData_RadioEnableWrongType()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = 123,
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
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.2

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.3
      --Description: OnInteriorVehicleData with frequencyInteger parameter of wrong type
        function Test:OnInteriorVehicleData_FrequencyIntegerWrongType()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = "105",
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
      --End Test case ResponseWrongTypeNotification.12.3

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.4
      --Description: OnInteriorVehicleData with frequencyFraction parameter of wrong type
        function Test:OnInteriorVehicleData_FrequencyFractionWrongType()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = "3",
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
      --End Test case ResponseWrongTypeNotification.12.4

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.5
      --Description: OnInteriorVehicleData with band parameter of wrong type
        function Test:OnInteriorVehicleData_BandWrongType()

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
                          band = 123,
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
      --End Test case ResponseWrongTypeNotification.12.5

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.6
      --Description: OnInteriorVehicleData with hdChannel parameter of wrong type
        function Test:OnInteriorVehicleData_HdChannelWrongType()

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
                          hdChannel = "1",
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
      --End Test case ResponseWrongTypeNotification.12.6

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.7
      --Description: OnInteriorVehicleData with state parameter of wrong type
        function Test:OnInteriorVehicleData_StateWrongType()

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
                          state = true,
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
      --End Test case ResponseWrongTypeNotification.12.7

        -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.8
      --Description: OnInteriorVehicleData with availableHDs parameter of wrong type
        function Test:OnInteriorVehicleData_AvailableHDsWrongType()

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
                          availableHDs = "1",
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
      --End Test case ResponseWrongTypeNotification.12.8

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.9
      --Description: OnInteriorVehicleData with signalStrength parameter of wrong type
        function Test:OnInteriorVehicleData_SignalStrengthWrongType()

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
                          signalStrength = "50",
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
      --End Test case ResponseWrongTypeNotification.12.9

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.10
      --Description: OnInteriorVehicleData with PS parameter of wrong type
        function Test:OnInteriorVehicleData_PSWrongType()

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
                            PS = 12345678,
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
      --End Test case ResponseWrongTypeNotification.12.10

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.11
      --Description: OnInteriorVehicleData with RT parameter of wrong type
        function Test:OnInteriorVehicleData_RTWrongType()

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
                            RT = 123,
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
      --End Test case ResponseWrongTypeNotification.12.11

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.12
      --Description: OnInteriorVehicleData with CT parameter of wrong type
        function Test:OnInteriorVehicleData_CTWrongType()

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
                            CT = 123456789123456789123456,
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
      --End Test case ResponseWrongTypeNotification.12.12

      -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.13
      --Description: OnInteriorVehicleData with PI parameter of wrong type
        function Test:OnInteriorVehicleData_PIWrongType()

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
                            PI = false,
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
      --End Test case ResponseWrongTypeNotification.12.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.14
      --Description: OnInteriorVehicleData with PTY parameter of wrong type
        function Test:OnInteriorVehicleData_PTYWrongType()

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
                            PTY = "0",
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
      --End Test case ResponseWrongTypeNotification.12.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.15
      --Description: OnInteriorVehicleData with TP parameter of wrong type
        function Test:OnInteriorVehicleData_TPWrongType()

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
                            TP = "true",
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
      --End Test case ResponseWrongTypeNotification.12.15

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.16
      --Description: OnInteriorVehicleData with TA parameter of wrong type
        function Test:OnInteriorVehicleData_TAWrongType()

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
                            TA = "false",
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
      --End Test case ResponseWrongTypeNotification.12.16

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.17
      --Description: OnInteriorVehicleData with REG parameter of wrong type
        function Test:OnInteriorVehicleData_REGWrongType()

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
                            REG = 123
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
      --End Test case ResponseWrongTypeNotification.12.17

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.18
      --Description: OnInteriorVehicleData with signalChangeThreshold parameter of wrong type
        function Test:OnInteriorVehicleData_SignalChangeThresholdWrongType()

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
                          signalChangeThreshold = "10"
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
      --End Test case ResponseWrongTypeNotification.12.18

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.19
      --Description: OnInteriorVehicleData with moduleType parameter of wrong type
        function Test:OnInteriorVehicleData_ModuleTypeWrongType()

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
                        moduleType = true,
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
      --End Test case ResponseWrongTypeNotification.12.19

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.20
      --Description: OnInteriorVehicleData with clospan parameter of wrong type
        function Test:OnInteriorVehicleData_ClospanWrongType()

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
                          colspan = "2",
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
      --End Test case ResponseWrongTypeNotification.12.20

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.21
      --Description: OnInteriorVehicleData with row parameter of wrong type
        function Test:OnInteriorVehicleData_RowWrongType()

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
                          row = "0",
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
      --End Test case ResponseWrongTypeNotification.12.21

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.22
      --Description: OnInteriorVehicleData with rowspan parameter of wrong type
        function Test:OnInteriorVehicleData_RowspanWrongType()

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
                          rowspan = "2",
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
      --End Test case ResponseWrongTypeNotification.12.22

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.23
      --Description: OnInteriorVehicleData with col parameter of wrong type
        function Test:OnInteriorVehicleData_ColWrongType()

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
                          col = "0",
                          levelspan = 1,
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.23

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.24
      --Description: OnInteriorVehicleData with levelspan parameter of wrong type
        function Test:OnInteriorVehicleData_LevelspanWrongType()

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
                          levelspan = "1",
                          level = 0
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.24

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.25
      --Description: OnInteriorVehicleData with level parameter of wrong type
        function Test:OnInteriorVehicleData_LevelWrongType()

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
                          level = "0"
                        }
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.25

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.26
      --Description: OnInteriorVehicleData with fanSpeed parameter of wrong type
        function Test:OnInteriorVehicleData_FanSpeedWrongType()

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
                    fanSpeed = "50",
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
      --End Test case ResponseWrongTypeNotification.12.26

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.27
      --Description: OnInteriorVehicleData with circulateAirEnable parameter of wrong type
        function Test:OnInteriorVehicleData_CirculateAirEnableWrongType()

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
                    circulateAirEnable = "true",
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
      --End Test case ResponseWrongTypeNotification.12.27

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.28
      --Description: OnInteriorVehicleData with dualModeEnable parameter of wrong type
        function Test:OnInteriorVehicleData_DualModeEnableWrongType()

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
                    dualModeEnable = "true",
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
      --End Test case ResponseWrongTypeNotification.12.28

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.29
      --Description: OnInteriorVehicleData with currentTemp parameter of wrong type
        function Test:OnInteriorVehicleData_CurrentTempWrongType()

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
                    currentTemp = false,
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
      --End Test case ResponseWrongTypeNotification.12.29

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.30
      --Description: OnInteriorVehicleData with defrostZone parameter of wrong type
        function Test:OnInteriorVehicleData_DefrostZoneWrongType()

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
                    defrostZone = 123,
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
      --End Test case ResponseWrongTypeNotification.12.30

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.31
      --Description: OnInteriorVehicleData with acEnable parameter of wrong type
        function Test:OnInteriorVehicleData_AcEnableWrongType()

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
                    acEnable = "true",
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
      --End Test case ResponseWrongTypeNotification.12.31

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.32
      --Description: OnInteriorVehicleData with desiredTemp parameter of wrong type
        function Test:OnInteriorVehicleData_DesiredTempWrongType()

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
                    desiredTemp = "24",
                    autoModeEnable = true,
                    temperatureUnit = "CELSIUS"
                  }
                }
                })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.32

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.33
      --Description: OnInteriorVehicleData with autoModeEnable parameter of wrong type
        function Test:OnInteriorVehicleData_AutoModeEnableWrongType()

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
                    desiredTemp = 24,
                    autoModeEnable = 123,
                    temperatureUnit = "CELSIUS"
                  }
                }
                })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.33

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.34
      --Description: OnInteriorVehicleData with TemperatureUnit parameter of wrong type
        function Test:OnInteriorVehicleData_TemperatureUnitWrongType()

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
                    desiredTemp = 24,
                    autoModeEnable = true,
                    temperatureUnit = 123
                  }
                }
                })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.34

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.35
      --Description: OnInteriorVehicleData with moduleData parameter of wrong type
        function Test:OnInteriorVehicleData_ModuleDataWrongType()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData = "abc"
                })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.35

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.36
      --Description: OnInteriorVehicleData with climateControlData parameter of wrong type
        function Test:OnInteriorVehicleData_ClimateControlDataWrongType()

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
                  climateControlData = "  a b c  "
                }
                })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.36

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.37
      --Description: OnInteriorVehicleData with radioControlData parameter of wrong type
        function Test:OnInteriorVehicleData_RadioControlDataDataWrongType()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData",
              {
                moduleData =
                {
                  radioControlData = true,
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
      --End Test case ResponseWrongTypeNotification.12.37

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.38
      --Description: OnInteriorVehicleData with moduleZone parameter of wrong type
        function Test:OnInteriorVehicleData_ModuleZoneDataDataWrongType()

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
                  moduleZone = true
                }
                })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseWrongTypeNotification.12.38

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.39
      --Description: OnInteriorVehicleData with rdsData parameter of wrong type
        function Test:OnInteriorVehicleData_RdsDataWrongType()

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
                          rdsData = true,
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
      --End Test case ResponseWrongTypeNotification.12.39

      --Begin Test case ResponseWrongTypeNotification.12.39
      --Description: send notification with all params WrongType
        function Test:OnSetDriversDevice_WrongTypeAllParams()

          --hmi side: sending RC.OnSetDriversDevice notification
          self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {
                  device = {
                    name = true,
                    id = "1",
                    isSDLAllowed = "true"
                  }
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseWrongTypeNotification.12.39

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.40
      --Description: send notification with name WrongType
        function Test:OnSetDriversDevice_WrongTypeName()

          --hmi side: sending RC.OnSetDriversDevice notification
          self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {
                  device = {
                    name = 123,
                    id = 1,
                    isSDLAllowed = true
                  }
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseWrongTypeNotification.12.40

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.41
      --Description: send notification with ID WrongType
        function Test:OnSetDriversDevice_WrongTypeID()

          --hmi side: sending RC.OnSetDriversDevice notification
          self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {
                  device = {
                    name = "127.0.0.1",
                    id = {1},
                    isSDLAllowed = true
                  }
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseWrongTypeNotification.12.41

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeNotification.12.42
      --Description: send notification with device WrongType
        function Test:OnSetDriversDevice_WrongTypeDevice()

          --hmi side: sending RC.OnSetDriversDevice notification
          self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {
                  device = true
          })

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseWrongTypeNotification.12.42

    -----------------------------------------------------------------------------------------

      --<TODO>: Question: Requirement
      --Begin Test case ResponseWrongTypeNotification.12.43
      --Description: send notification with allowed WrongType
        function Test:OnReverseAppsAllowing_WrongTypeAllowed()

          --hmi side: sending VehicleInfo.OnReverseAppsAllowing notification
          self.hmiConnection:SendNotification("VehicleInfo.OnReverseAppsAllowing", {allowed = "true"})

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)

        end
      --End Test case ResponseWrongTypeNotification.12.43

  --End Test case ResponseWrongTypeNotification.12
--=================================================END TEST CASES 12==========================================================--


function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end