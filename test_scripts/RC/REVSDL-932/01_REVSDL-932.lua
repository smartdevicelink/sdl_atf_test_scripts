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



--=================================================BEGIN TEST CASES 1==========================================================--
  --Begin Test suit CommonRequestCheck.1 for ButtonPress

  --Description: Validation App's RPC for ButtonPress request

  --Begin Test case CommonRequestCheck.1
  --Description:  --mandatory param is missing
          --[Requirement]: 2. Mandatory params missing

    --Requirement/Diagrams id in jira:
        --Requirement
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/115807/115807_Req_1_2_of_Requirement.png

    --Verification criteria:
        --In case app sends RPC with one or more mandatory-by-mobile_API parameters missing, RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app

      --Begin Test case CommonRequestCheck.1.1
      --Description: ButtonPress with all parameters missing
        function Test:ButtonPress_AllParamsMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.2
      --Description: ButtonPress with Colspan parameter missing
        function Test:ButtonPress_ColspanMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.3
      --Description: ButtonPress with row parameter missing
        function Test:ButtonPress_RowMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.4
      --Description: ButtonPress with rowspan parameter missing
        function Test:ButtonPress_RowspanMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.5
      --Description: ButtonPress with col parameter missing
        function Test:ButtonPress_ColMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "RADIO",
            buttonPressMode = "SHORT",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.6
      --Description: ButtonPress with levelspan parameter missing
        function Test:ButtonPress_LevelspanMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.7
      --Description: ButtonPress with level parameter missing
        function Test:ButtonPress_levelMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.8
      --Description: ButtonPress with moduleType parameter missing
        function Test:ButtonPress_ModuleTypeMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.9
      --Description: ButtonPress with buttonPressMode parameter missing
        function Test:ButtonPress_ButtonPressModeMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.10
      --Description: ButtonPress with buttonName parameter missing
        function Test:ButtonPress_ButtonNameMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.10

      --Begin Test case CommonRequestCheck.1.11
      --Description: ButtonPress with zone parameter missing
        function Test:ButtonPress_ZoneMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.11

      --Begin Test case CommonRequestCheck.1.12
      --Description: ButtonPress with rowspan and buttonPressMode parameters missing
        function Test:ButtonPress_RowspanAndButtonPressModeMissing()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.12

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
      --Description: ButtonPress with all parameters out of bounds
        function Test:ButtonPress_AllParametersOutLowerBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = -1,
              row = -1,
              rowspan = -1,
              col = -1,
              levelspan = -1,
              level = -1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2
      --Description: ButtonPress with Colspan parameter out of bounds
        function Test:ButtonPress_ColspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = -1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.3
      --Description: ButtonPress with row parameter out of bounds
        function Test:ButtonPress_RowOutLowerBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = -1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.4
      --Description: ButtonPress with rowspan parameter out of bounds
        function Test:ButtonPress_RowspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = -1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.5
      --Description: ButtonPress with col parameter out of bounds
        function Test:ButtonPress_ColOutLowerBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = -1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.6
      --Description: ButtonPress with levelspan parameter out of bounds
        function Test:ButtonPress_LevelspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = -1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.7
      --Description: ButtonPress with level parameter out of bounds
        function Test:ButtonPress_LevelOutLowerBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = -1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.8
      --Description: ButtonPress with all parameters out of bounds
        function Test:ButtonPress_AllParametersOutUpperBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 101,
              row = 101,
              rowspan = 101,
              col = 101,
              levelspan = 101,
              level = 101
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.9
      --Description: ButtonPress with Colspan parameter out of bounds
        function Test:ButtonPress_ColspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 101,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.10
      --Description: ButtonPress with row parameter out of bounds
        function Test:ButtonPress_RowOutUpperBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 101,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.11
      --Description: ButtonPress with rowspan parameter out of bounds
        function Test:ButtonPress_RowspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 101,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.11

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.12
      --Description: ButtonPress with col parameter out of bounds
        function Test:ButtonPress_ColOutUpperBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 101,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.12

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.13
      --Description: ButtonPress with levelspan parameter out of bounds
        function Test:ButtonPress_LevelspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 101,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.13

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.14
      --Description: ButtonPress with level parameter out of bounds
        function Test:ButtonPress_LevelOutUpperBound()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 101
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
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
        function Test:ButtonPress_InvalidJson()
          self.mobileSession.correlationId = self.mobileSession.correlationId + 1

          local msg =
          {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 0,
          rpcFunctionId    = 100015,
          rpcCorrelationId = self.mobileSession.correlationId,
          payload          = '{"zone":{"colspan":1,"row":1,"rowspan":1,"col":1,"levelspan":1,"level":1},"moduleType":"CLIMATE","buttonPressMode":"LONG","buttonName" "AC_MAX"}'
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
      --Description: ButtonPress with all parameters of wrong type
        function Test:ButtonPress_AllParamsWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = "1",
              row = "1",
              rowspan = "1",
              col = "1",
              levelspan = "1",
              level = "1"
            },
            moduleType = 111,
            buttonPressMode = 111,
            buttonName = 111
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2
      --Description: ButtonPress with Colspan parameter of wrong type
        function Test:ButtonPress_ColspanWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = "1",
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.3
      --Description: ButtonPress with row parameter of wrong type
        function Test:ButtonPress_RowWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = "1",
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.4
      --Description: ButtonPress with rowspan parameter of wrong type
        function Test:ButtonPress_RowspanWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = "1",
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.5
      --Description: ButtonPress with col parameter of wrong type
        function Test:ButtonPress_ColWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = "1",
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6
      --Description: ButtonPress with levelspan parameter of wrong type
        function Test:ButtonPress_LevelspanWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = "1",
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.7
      --Description: ButtonPress with level parameter of wrong type
        function Test:ButtonPress_levelWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = "1"
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.8
      --Description: ButtonPress with moduleType parameter of wrong type
        function Test:ButtonPress_ModuleTypeWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = 111,
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.9
      --Description: ButtonPress with buttonPressMode parameter of wrong type
        function Test:ButtonPress_ButtonPressModeWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = 111,
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.10
      --Description: ButtonPress with buttonName parameter of wrong type
        function Test:ButtonPress_ButtonNameWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = 111
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.10

      --Begin Test case CommonRequestCheck.5.11
      --Description: ButtonPress with zone elements parameter of wrong type
        function Test:ButtonPress_ZoneElementsWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = "1",
              row = true,
              rowspan = false,
              col = 1,
              levelspan = "1",
              level = "abc"
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.11

      --Begin Test case CommonRequestCheck.5.12
      --Description: ButtonPress with rowspan and buttonPressMode parameters of wrong type
        function Test:ButtonPress_RowspanAndButtonPressModeWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = "1",
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleType = "CLIMATE",
            buttonPressMode = true,
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.12

      --Begin Test case CommonRequestCheck.5.13
      --Description: ButtonPress with zone parameter of wrong type
        function Test:ButtonPress_ZoneWrongType()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone = true,
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.13

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
      --Description: app sends RPC with fake param inside zone
        function Test:ButtonPress_FakeParamsInsideZone()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              fake1 = true,
              colspan = 2,
              row = 0,
              rowspan = 2,
              fake2 = 1,
              col = 0,
              levelspan = 1,
              level = 0
            },
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "LONG",
                  buttonName = "AC_MAX"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.6.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2
      --Description: app sends RPC with fake param outside zone
        function Test:ButtonPress_FakeParamsOutsideZone()
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
            fake1 = "RADIO",
            moduleType = "CLIMATE",
            buttonPressMode = "LONG",
            fake3 = false,
            buttonName = "AC_MAX"
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "LONG",
                  buttonName = "AC_MAX"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
          :ValidIf (function(_,data)
              if data.payload.fake1 then
                print(" SDL resend fake parameter to mobile app ")
                return false
              else
                return true
              end
          end)

        end
      --End Test case CommonRequestCheck.6.2
  --End Test case CommonRequestCheck.6

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.1

--=================================================END TEST CASES 1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end