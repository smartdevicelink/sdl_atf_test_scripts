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

--=================================================BEGIN TEST CASES 3==========================================================--
  --Begin Test case ResponseWrongTypeCheck.3
  --Description:  --Invalid response expected by mobile app

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --<4.>In case a mobile app sends a valid request to RSDL, RSDL transfers this request to HMI, and HMI responds with one or more params of wrong type per rc-HMI_API to RSDL, RSDL must log an error and respond with "resultCode: GENERIC_ERROR, success: false, info: 'Invalid response from the vehicle'" to this mobile app's request (Exception: GetInteriorVehicleDataCapabilities, see Requirement).

      --Begin Test case case ResponseWrongTypeCheck.3.1
      --Description: GetInteriorVehicleDataCapabilities with all parameters of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeAllParamsWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
              colspan = "1",
              row = "1",
              rowspan = "1",
              col = "1",
              levelspan = "1",
              level = "1"
            },
            moduleType = {111, 111}
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.1

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.2
      --Description: GetInteriorVehicleDataCapabilities with Colspan parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeColspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
              colspan = "1",
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "RADIO"
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.2

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.3
      --Description: GetInteriorVehicleDataCapabilities with row parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeRowWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
                colspan = 2,
                row = "0",
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0
            },
            moduleType = "RADIO"
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.3

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.4
      --Description: GetInteriorVehicleDataCapabilities with rowspan parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeRowspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
                colspan = 2,
                row = 0,
                rowspan = "2",
                col = 0,
                levelspan = 1,
                level = 0
            },
            moduleType = "RADIO"
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.4

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.5
      --Description: GetInteriorVehicleDataCapabilities with col parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeColWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = "0",
                levelspan = 1,
                level = 0
            },
            moduleType = "RADIO"
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.5

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.6
      --Description: GetInteriorVehicleDataCapabilities with levelspan parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeLevelspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = 0,
                levelspan = "1",
                level = 0
            },
            moduleType = "RADIO"
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.6

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.7
      --Description: GetInteriorVehicleDataCapabilities with level parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposelevelWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = "0"
            },
            moduleType = "RADIO"
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.7

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.8
      --Description: GetInteriorVehicleDataCapabilities with moduleType parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeModuleTypeWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
            interiorVehicleDataCapabilities = {
            {
              moduleZone = {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0
                },
                moduleType = 111
              }
            }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.8

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.9
      --Description: GetInteriorVehicleDataCapabilities with zone parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeZoneWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
              colspan = "1",
              row = true,
              rowspan = false,
              col = 1,
              levelspan = "1",
              level = "abc"
            },
            moduleType = "RADIO"
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.9

    -----------------------------------------------------------------------------------------

      --Begin Test case case ResponseWrongTypeCheck.3.10
      --Description: GetInteriorVehicleDataCapabilities with rowspan and ModuleType parameters of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ResposeRowspanAndModuleTypeWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
        :Do(function(_,data)
          --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
          interiorVehicleDataCapabilities = {
          {
          moduleZone = {
                colspan = 2,
                row = 0,
                rowspan = "2",
                col = 0,
                levelspan = 1,
                level = 0
            },
            moduleType = {111, "abc"}
          }
          }
          })
        end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                  moduleZone = {
                                                    col = 0,
                                                    row = 0,
                                                    level = 0,
                                                    colspan = 2,
                                                    rowspan = 2,
                                                    levelspan = 1
                                                  },
                                                  moduleType = "RADIO"
                                                }
                                            }
        })
        end
      --End Test case case ResponseWrongTypeCheck.3.10

    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.1
      --Description: SetInteriorVehicleData with all parameters of wrong type
        function Test:SetInteriorVehicleData_ResponseAllParamsWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})

        end
      --End Test case ResponseWrongTypeCheck.3.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.2
      --Description: SetInteriorVehicleData with radioEnable parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseRadioEnableWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.3
      --Description: SetInteriorVehicleData with frequencyInteger parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseFrequencyIntegerWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.4
      --Description: SetInteriorVehicleData with frequencyFraction parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseFrequencyFractionWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.5
      --Description: SetInteriorVehicleData with band parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseBandWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.5

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.6
      --Description: SetInteriorVehicleData with hdChannel parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseHdChannelWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.6

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.7
      --Description: SetInteriorVehicleData with state parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseStateWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.7

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.8
      --Description: SetInteriorVehicleData with availableHDs parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseAvailableHDsWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.8

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.9
      --Description: SetInteriorVehicleData with signalStrength parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseSignalStrengthWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.9

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.10
      --Description: SetInteriorVehicleData with PS parameter of wrong type
        function Test:SetInteriorVehicleData_ResponsePSWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.10

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.11
      --Description: SetInteriorVehicleData with RT parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseRTWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.11

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.12
      --Description: SetInteriorVehicleData with CT parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseCTWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.12

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.13
      --Description: SetInteriorVehicleData with PI parameter of wrong type
        function Test:SetInteriorVehicleData_ResponsePIWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.14
      --Description: SetInteriorVehicleData with PTY parameter of wrong type
        function Test:SetInteriorVehicleData_ResponsePTYWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.15
      --Description: SetInteriorVehicleData with TP parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseTPWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.15

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.16
      --Description: SetInteriorVehicleData with TA parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseTAWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.16

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.17
      --Description: SetInteriorVehicleData with REG parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseREGWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.17

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.18
      --Description: SetInteriorVehicleData with signalChangeThreshold parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseSignalChangeThresholdWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.18

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.19
      --Description: SetInteriorVehicleData with moduleType parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseModuleTypeWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.19

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.20
      --Description: SetInteriorVehicleData with clospan parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseClospanWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.20

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.21
      --Description: SetInteriorVehicleData with row parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseRowWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.21

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.22
      --Description: SetInteriorVehicleData with rowspan parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseRowspanWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.22

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.23
      --Description: SetInteriorVehicleData with col parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseColWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.23

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.24
      --Description: SetInteriorVehicleData with levelspan parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseLevelspanWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.24

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.25
      --Description: SetInteriorVehicleData with level parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseLevelWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.25

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.26
      --Description: SetInteriorVehicleData with fanSpeed parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseFanSpeedWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.26

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.27
      --Description: SetInteriorVehicleData with circulateAirEnable parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseCirculateAirEnableWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.27

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.28
      --Description: SetInteriorVehicleData with dualModeEnable parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseDualModeEnableWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.28

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.29
      --Description: SetInteriorVehicleData with currentTemp parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseCurrentTempWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.29

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.30
      --Description: SetInteriorVehicleData with defrostZone parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseDefrostZoneWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.30

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.31
      --Description: SetInteriorVehicleData with acEnable parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseAcEnableWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.31

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.32
      --Description: SetInteriorVehicleData with desiredTemp parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseDesiredTempWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.32

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.33
      --Description: SetInteriorVehicleData with autoModeEnable parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseAutoModeEnableWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.33

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.34
      --Description: SetInteriorVehicleData with TemperatureUnit parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseTemperatureUnitWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.34

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.35
      --Description: SetInteriorVehicleData with moduleData parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseModuleDataWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                moduleData = "abc"
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.35

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.36
      --Description: SetInteriorVehicleData with climateControlData parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseClimateControlDataWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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
                    temperatureUnit = "CELSIUS"
                  }
                }
            })

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
                row = 0,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0
              },
              climateControlData = "  a b c  "
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.36

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.37
      --Description: SetInteriorVehicleData with radioControlData parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseRadioControlDataDataWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.37

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.38
      --Description: SetInteriorVehicleData with moduleZone parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseModuleZoneDataDataWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.38

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.39
      --Description: SetInteriorVehicleData with rdsData parameter of wrong type
        function Test:SetInteriorVehicleData_ResponseRdsDataWrongType()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
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

        --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
                      rdsData = "  a b c ",
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.39


    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------



      --Begin Test case ResponseWrongTypeCheck.3.1
      --Description: GetInteriorVehicleData with all parameters of wrong type
        function Test:GetInteriorVehicleData_ResponseAllParamsWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})

        end
      --End Test case ResponseWrongTypeCheck.3.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.2
      --Description: GetInteriorVehicleData with radioEnable parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseRadioEnableWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.3
      --Description: GetInteriorVehicleData with frequencyInteger parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseFrequencyIntegerWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.4
      --Description: GetInteriorVehicleData with frequencyFraction parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseFrequencyFractionWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.5
      --Description: GetInteriorVehicleData with band parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseBandWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.5

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.6
      --Description: GetInteriorVehicleData with hdChannel parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseHdChannelWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.6

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.7
      --Description: GetInteriorVehicleData with state parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseStateWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.7

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.8
      --Description: GetInteriorVehicleData with availableHDs parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseAvailableHDsWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.8

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.9
      --Description: GetInteriorVehicleData with signalStrength parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseSignalStrengthWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.9

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.10
      --Description: GetInteriorVehicleData with PS parameter of wrong type
        function Test:GetInteriorVehicleData_ResponsePSWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.10

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.11
      --Description: GetInteriorVehicleData with RT parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseRTWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.11

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.12
      --Description: GetInteriorVehicleData with CT parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseCTWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.12

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.13
      --Description: GetInteriorVehicleData with PI parameter of wrong type
        function Test:GetInteriorVehicleData_ResponsePIWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.14
      --Description: GetInteriorVehicleData with PTY parameter of wrong type
        function Test:GetInteriorVehicleData_ResponsePTYWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.15
      --Description: GetInteriorVehicleData with TP parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseTPWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.15

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.16
      --Description: GetInteriorVehicleData with TA parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseTAWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.16

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.17
      --Description: GetInteriorVehicleData with REG parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseREGWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.17

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.18
      --Description: GetInteriorVehicleData with signalChangeThreshold parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseSignalChangeThresholdWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.18

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.19
      --Description: GetInteriorVehicleData with moduleType parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseModuleTypeWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.19

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.20
      --Description: GetInteriorVehicleData with clospan parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseClospanWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.20

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.21
      --Description: GetInteriorVehicleData with row parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseRowWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.21

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.22
      --Description: GetInteriorVehicleData with rowspan parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseRowspanWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.22

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.23
      --Description: GetInteriorVehicleData with col parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseColWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.23

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.24
      --Description: GetInteriorVehicleData with levelspan parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseLevelspanWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.24

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.25
      --Description: GetInteriorVehicleData with level parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseLevelWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.25

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.26
      --Description: GetInteriorVehicleData with fanSpeed parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseFanSpeedWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.26

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.27
      --Description: GetInteriorVehicleData with circulateAirEnable parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseCirculateAirEnableWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.27

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.28
      --Description: GetInteriorVehicleData with dualModeEnable parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseDualModeEnableWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.28

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.29
      --Description: GetInteriorVehicleData with currentTemp parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseCurrentTempWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.29

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.30
      --Description: GetInteriorVehicleData with defrostZone parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseDefrostZoneWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.30

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.31
      --Description: GetInteriorVehicleData with acEnable parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseAcEnableWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.31

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.32
      --Description: GetInteriorVehicleData with desiredTemp parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseDesiredTempWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.32

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.33
      --Description: GetInteriorVehicleData with autoModeEnable parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseAutoModeEnableWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.33

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.34
      --Description: GetInteriorVehicleData with TemperatureUnit parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseTemperatureUnitWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.34

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.35
      --Description: GetInteriorVehicleData with moduleData parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseModuleDataWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                moduleData = "abc"
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.35

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.36
      --Description: GetInteriorVehicleData with climateControlData parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseClimateControlDataWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.36

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.37
      --Description: GetInteriorVehicleData with radioControlData parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseRadioControlDataDataWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.37

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.38
      --Description: GetInteriorVehicleData with moduleZone parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseModuleZoneDataDataWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.38

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseWrongTypeCheck.3.39
      --Description: GetInteriorVehicleData with rdsData parameter of wrong type
        function Test:GetInteriorVehicleData_ResponseRdsDataWrongType()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseWrongTypeCheck.3.39

  --End Test case ResponseWrongTypeCheck.3
--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end