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
-------------------------Requirement: App's RPCs validation rules-----------------------------
---Check: RSDL validate each and every RPC that app sends per "Remote-Control-Mobile-API"----
---------------------------------------------------------------------------------------------
  --Begin Test suit CommonRequestCheck

  --Description: TC's checks processing
    -- mandatory param is missing
    -- param has an out-of-bounds value
    -- invalid json
    -- string param with invalid characters
    -- param of wrong type

--=================================================BEGIN TEST CASES 3==========================================================--
  --Begin Test suit CommonRequestCheck.3 for GetInteriorVehicleData

  --Description: Validation App's RPC for GetInteriorVehicleData request

  --Begin Test suit CommonRequestCheck

  --Description: TC's checks processing
    -- mandatory param is missing
    -- param has an out-of-bounds value
    -- invalid json
    -- string param with invalid characters
    -- param of wrong type


  --Begin Test case CommonRequestCheck.1
  --Description:  --mandatory param is missing
          --[Requirement]: 2. Mandatory params missing

    --Requirement/Diagrams id in jira:
        --Requirement
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/115807/115807_Req_1_2_of_Requirement.png

    --Verification criteria:
        --In case app sends RPC with one or more mandatory-by-mobile_API parameters missing, RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app

  --RELATE TO QUESTION: Requirement: per current API, "GetInteriorVehicleDataCapabilities" should not be tested against "omitted mandatory parameters" requirement.

      --Begin Test case CommonRequestCheck.1.1
      --Description: GetInteriorVehicleData with all parameters missing
        function Test:GetInteriorVehicleData_AllParamsMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.2
      --Description: GetInteriorVehicleData with Colspan parameter missing
        function Test:GetInteriorVehicleData_ColspanMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.3
      --Description: GetInteriorVehicleData with row parameter missing
        function Test:GetInteriorVehicleData_RowMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.4
      --Description: GetInteriorVehicleData with rowspan parameter missing
        function Test:GetInteriorVehicleData_RowspanMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.5
      --Description: GetInteriorVehicleData with col parameter missing
        function Test:GetInteriorVehicleData_ColMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.6
      --Description: GetInteriorVehicleData with levelspan parameter missing
        function Test:GetInteriorVehicleData_LevelspanMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.7
      --Description: GetInteriorVehicleData with level parameter missing
        function Test:GetInteriorVehicleData_levelMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.8
      --Description: GetInteriorVehicleData with moduleType parameter missing
        function Test:GetInteriorVehicleData_ModuleTypeMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.9
      --Description: GetInteriorVehicleData with moduleZone parameter missing
        function Test:GetInteriorVehicleData_ModuleZoneMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE"
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.10
      --Description: GetInteriorVehicleData with moduleDescription parameter missing
        function Test:GetInteriorVehicleData_ModuleDescriptionMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.11
      --Description: GetInteriorVehicleData with subscribe parameter missing
        function Test:GetInteriorVehicleData_SubscribeMissing()
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
                level = 0
              }
            }
          })

        --hmi side: expect RC.GetInteriorVehicleData request
        EXPECT_HMICALL("RC.GetInteriorVehicleData")
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleData response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { moduleData = {
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

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

        end
      --End Test case CommonRequestCheck.1.11

  --End Test case CommonRequestCheck.1

    -----------------------------------------------------------------------------------------

  --Begin Test case CommonRequestCheck.2
  --Description:  --param has an out-of-bounds value
          --[Requirement]: 3 Parameters out of bounds

    --Requirement/Diagrams id in jira:
        --Requirement
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/115809/115809_Req_1_3_of_Requirement.png

    --Verification criteria:
        --In case app sends RPC with one or more mandatory or non-mandatory by-mobile_API parameters out of bounds, RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app

      --Begin Test case CommonRequestCheck.2.1
      --Description: GetInteriorVehicleData with all parameters out of bounds
        function Test:GetInteriorVehicleData_AllParametersOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = -1,
                row = -1,
                rowspan = -1,
                col = -1,
                levelspan = -1,
                level = -1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2
      --Description: GetInteriorVehicleData with Colspan parameter out of bounds
        function Test:GetInteriorVehicleData_ColspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = -1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.3
      --Description: GetInteriorVehicleData with row parameter out of bounds
        function Test:GetInteriorVehicleData_RowOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = -1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.4
      --Description: GetInteriorVehicleData with rowspan parameter out of bounds
        function Test:GetInteriorVehicleData_RowspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = -1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.5
      --Description: GetInteriorVehicleData with col parameter out of bounds
        function Test:GetInteriorVehicleData_ColOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = -1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.6
      --Description: GetInteriorVehicleData with levelspan parameter out of bounds
        function Test:GetInteriorVehicleData_LevelspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = -1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.7
      --Description: GetInteriorVehicleData with level parameter out of bounds
        function Test:GetInteriorVehicleData_LevelOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = -1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.8
      --Description: GetInteriorVehicleData with all parameters out of bounds
        function Test:GetInteriorVehicleData_AllParametersOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 101,
                row = 101,
                rowspan = 101,
                col = 101,
                levelspan = 101,
                level = 101
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.9
      --Description: GetInteriorVehicleData with Colspan parameter out of bounds
        function Test:GetInteriorVehicleData_ColspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 101,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.10
      --Description: GetInteriorVehicleData with row parameter out of bounds
        function Test:GetInteriorVehicleData_RowOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 101,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.11
      --Description: GetInteriorVehicleData with rowspan parameter out of bounds
        function Test:GetInteriorVehicleData_RowspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 101,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.11

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.12
      --Description: GetInteriorVehicleData with col parameter out of bounds
        function Test:GetInteriorVehicleData_ColOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 101,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.12

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.13
      --Description: GetInteriorVehicleData with levelspan parameter out of bounds
        function Test:GetInteriorVehicleData_LevelspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 101,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.13

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.14
      --Description: GetInteriorVehicleData with level parameter out of bounds
        function Test:GetInteriorVehicleData_LevelOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 101
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.14

  --End Test case CommonRequestCheck.2

    -----------------------------------------------------------------------------------------

  --Begin Test case CommonRequestCheck.3
  --Description:  --invalid json
          --[Requirement]: 4. Wrong json

    --Requirement/Diagrams id in jira:
        --Requirement
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/115813/115813_Req_1_4_Requirement.png

    --Verification criteria:
        --In case app sends RPC in wrong JSON, RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app

      --Begin Test case CommonRequestCheck.3.1
      --Description: Request with invalid JSON syntax (INVALID_DATA)
        function Test:GetInteriorVehicleData_InvalidJson()
          self.mobileSession.correlationId = self.mobileSession.correlationId + 1

          local msg =
          {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 0,
          rpcFunctionId    = 100017,
          rpcCorrelationId = self.mobileSession.correlationId,
          payload          = '{"moduleDescription":{"moduleType":"CLIMATE","moduleZone":{"col":1,"colspan":1,"level":1,"levelspan":1,"row":1,"rowspan":1}},"subscribe" false}'
          }
          self.mobileSession:Send(msg)
          self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.3.1

  --End Test case CommonRequestCheck.3

    -----------------------------------------------------------------------------------------

  --Begin Test case CommonRequestCheck.4
  --Description:  --invalid json
          --[Requirement]: 5. String with invalid characters

    --Requirement/Diagrams id in jira:
        --Requirement
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/115818/115818_Req_1_5_of_Requirement.png

    --Verification criteria:
        --In case app sends RPC with invalid characters in param of string type, RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app

    --SKIPPED because "Note: currently none of the listed RPCs has a string param." cloned to Requirement [Requirement]: 6. Parameter of wrong type

  --End Test case CommonRequestCheck.4

    -----------------------------------------------------------------------------------------

  --Begin Test case CommonRequestCheck.5
  --Description:  --param of wrong type
          --[Requirement]: 6. Parameter of wrong type

    --Requirement/Diagrams id in jira:
        --Requirement
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/115819/115819_Req_1_6_of_Requirement.png

    --Verification criteria:
        --In case app sends RPC with param of wrong type, RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app

      --Begin Test case CommonRequestCheck.5.1
      --Description: GetInteriorVehicleData with all parameters of wrong type
        function Test:GetInteriorVehicleData_AllParamsWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = 1234567,
              moduleZone =
              {
                clospan = "1",
                row = "1",
                rowspan = "1",
                col = "1",
                levelspan = "1",
                level = "1"
              }
            },
            subscribe = "true"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2
      --Description: GetInteriorVehicleData with Colspan parameter of wrong type
        function Test:GetInteriorVehicleData_ColspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = "1",
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.3
      --Description: GetInteriorVehicleData with row parameter of wrong type
        function Test:GetInteriorVehicleData_RowWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = true,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.4
      --Description: GetInteriorVehicleData with rowspan parameter of wrong type
        function Test:GetInteriorVehicleData_RowspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = "1",
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.5
      --Description: GetInteriorVehicleData with col parameter of wrong type
        function Test:GetInteriorVehicleData_ColWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = "1",
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6
      --Description: GetInteriorVehicleData with levelspan parameter of wrong type
        function Test:GetInteriorVehicleData_LevelspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = "1",
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.7
      --Description: GetInteriorVehicleData with level parameter of wrong type
        function Test:GetInteriorVehicleData_levelWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = "1"
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.8
      --Description: GetInteriorVehicleData with moduleType parameter of wrong type
        function Test:GetInteriorVehicleData_ModuleTypeWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = true,
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.9
      --Description: GetInteriorVehicleData with subscribe parameter of wrong type
        function Test:GetInteriorVehicleData_SubscribeModeWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            },
            subscribe = "true"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.10
      --Description: GetInteriorVehicleData with ModuleZone parameter of wrong type
        function Test:GetInteriorVehicleData_ModuleZoneWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
              moduleZone = "abc"
            },
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.11
      --Description: GetInteriorVehicleData with ModuleDescription parameter of wrong type
        function Test:GetInteriorVehicleData_ModuleDescriptionWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription = "abc",
            subscribe = true
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.11

  --End Test case CommonRequestCheck.5

    -----------------------------------------------------------------------------------------

  --Begin Test case CommonRequestCheck.6
  --Description:  --RSDL cuts off the fake param (non-existent per Mobile_API) from app's RPC.
          --[Requirement]: 7. Fake params

    --Requirement/Diagrams id in jira:
        --Requirement
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/116227/116227_Req_1_2_7_of_Requirement.png

    --Verification criteria:
        --In case app sends RPC with fake param (non-existent per Mobile_API), RSDL must cut this param off from the RPC and then validate this RPC and process as assigned.

      --Begin Test case CommonRequestCheck.6.1
      --Description: app sends RPC with fake param inside moduleZone
        function Test:GetInteriorVehicleData_FakeParamsInsideModuleZone()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "RADIO",
              moduleZone =
              {
                fake1 = 1,
                colspan = 2,
                row = 0,
                rowspan = 2,
                fake2 = true,
                col = 0,
                levelspan = 1,
                level = 0,
                fake3 = "abc  xyz  "
              }
            },
            subscribe = true
          })

        --hmi side: expect RC.GetInteriorVehicleData request
        EXPECT_HMICALL("RC.GetInteriorVehicleData")
        :ValidIf (function(_,data)
            if data.params.moduleDescription.moduleZone.fake1 then
              print(" --SDL sends fake parameter to HMI ")
              for key,value in pairs(data.params) do print(key,value) end
              return false
            else
              return true
            end
          end)
          :Timeout(3000)

        end
      --End Test case CommonRequestCheck.6.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2
      --Description: app sends RPC with fake param outside moduleZone
        function Test:GetInteriorVehicleData_FakeParamsOutsideModuleZone()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              fake1 = 123,
              moduleType = "RADIO",
              moduleZone =
              {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0
              },
              fake2 = true
            },
            fake3 = "  abc  xyz   ",
            subscribe = true
          })

        --hmi side: expect RC.GetInteriorVehicleData request
        EXPECT_HMICALL("RC.GetInteriorVehicleData")
        :ValidIf (function(_,data)
            if data.params.moduleDescription.fake1 then
              print(" --SDL sends fake parameter to HMI ")
              for key,value in pairs(data.params) do print(key,value) end
              return false
            else
              return true
            end
          end)
          :Timeout(3000)
        end
      --End Test case CommonRequestCheck.6.2

  --End Test case CommonRequestCheck.6

    -----------------------------------------------------------------------------------------

--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end