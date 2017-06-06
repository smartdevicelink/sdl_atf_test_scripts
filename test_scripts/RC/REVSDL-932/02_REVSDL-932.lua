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
-------------------------------------STARTING COMMON FUNCTIONS-------------------------------
---------------------------------------------------------------------------------------------

--Create ModuleType for maxsize=1000. Using to perform test moduleType OverUpperBound case.
-------strModuleType<String>: "RADIO" or "CLIMATE"
-------iMaxsize<Integer>  : the length or array
local function CreateModuleTypes(strModuleType, iMaxsize)
  local items = {}
  for i=1, iMaxsize do
    table.insert(items, i, strModuleType)
  end
  return items
end

---------------------------------------------------------------------------------------------
----------------------------------------END COMMON FUNCTIONS---------------------------------
---------------------------------------------------------------------------------------------




---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
  --Begin Precondition.1. Need to be uncomment for checking Driver's device case
  --[[Description: Activation App by sending SDL.ActivateApp

    function Test:WaitActivation()

      --mobile side: Expect OnHMIStatus notification
      EXPECT_NOTIFICATION("OnHMIStatus")

      --hmi side: sending SDL.ActivateApp request
      local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                            { appID = self.applications["Test Application"] })

      --hmi side: send request RC.OnSetDriversDevice
      self.hmiConnection:SendNotification("RC.OnSetDriversDevice",
      {device = {name = "127.0.0.1", id = 1, isSDLAllowed = true}})

      --hmi side: Waiting for SDL.ActivateApp response
      EXPECT_HMIRESPONSE(rid)

    end]]
  --End Precondition.1

  -----------------------------------------------------------------------------------------



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

--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test suit CommonRequestCheck.2 for GetInteriorVehicleDataCapabilities

  --Description: Validation App's RPC for GetInteriorVehicleDataCapabilities request

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
      --Description: GetInteriorVehicleDataCapabilities with level parameter missing
        function Test:GetInteriorVehicleDataCapabilities_levelMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1
            },
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.2
      --Description: GetInteriorVehicleDataCapabilities with Colspan parameter missing
        function Test:GetInteriorVehicleDataCapabilities_ColspanMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
          {
            zone =
            {
              row = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.3
      --Description: GetInteriorVehicleDataCapabilities with row parameter missing
        function Test:GetInteriorVehicleDataCapabilities_RowMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
          {
            zone =
            {
              colspan = 1,
              rowspan = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.4
      --Description: GetInteriorVehicleDataCapabilities with rowspan parameter missing
        function Test:GetInteriorVehicleDataCapabilities_RowspanMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              col = 1,
              levelspan = 1,
              level = 1
            },
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.5
      --Description: GetInteriorVehicleDataCapabilities with col parameter missing
        function Test:GetInteriorVehicleDataCapabilities_ColMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              levelspan = 1,
              level = 1
            },
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.6
      --Description: GetInteriorVehicleDataCapabilities with levelspan parameter missing
        function Test:GetInteriorVehicleDataCapabilities_LevelspanMissing()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
          {
            zone =
            {
              colspan = 1,
              row = 1,
              rowspan = 1,
              col = 1,
              level = 1
            },
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.6

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
      --Description: GetInteriorVehicleDataCapabilities with all parameters out of bounds
        function Test:GetInteriorVehicleDataCapabilities_AllParametersOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2
      --Description: GetInteriorVehicleDataCapabilities with Colspan parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_ColspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.3
      --Description: GetInteriorVehicleDataCapabilities with row parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_RowOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.4
      --Description: GetInteriorVehicleDataCapabilities with rowspan parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_RowspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.5
      --Description: GetInteriorVehicleDataCapabilities with col parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_ColOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.6
      --Description: GetInteriorVehicleDataCapabilities with levelspan parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_LevelspanOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.7
      --Description: GetInteriorVehicleDataCapabilities with level parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_LevelOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.8
      --Description: GetInteriorVehicleDataCapabilities with moduleType parameters out of bounds. minisize = 1
        function Test:GetInteriorVehicleDataCapabilities_ModuleTypeOutLowerBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.9
      --Description: GetInteriorVehicleDataCapabilities with all parameters out of bounds
        function Test:GetInteriorVehicleDataCapabilities_AllParametersOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = CreateModuleTypes("RADIO", 1001)
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.10
      --Description: GetInteriorVehicleDataCapabilities with Colspan parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_ColspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.11
      --Description: GetInteriorVehicleDataCapabilities with row parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_RowOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.11

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.12
      --Description: GetInteriorVehicleDataCapabilities with rowspan parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_RowspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.12

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.13
      --Description: GetInteriorVehicleDataCapabilities with col parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_ColOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.13

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.14
      --Description: GetInteriorVehicleDataCapabilities with levelspan parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_LevelspanOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.14

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.15
      --Description: GetInteriorVehicleDataCapabilities with level parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_LevelOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.15

      --Begin Test case CommonRequestCheck.2.16
      --Description: GetInteriorVehicleDataCapabilities with moduleType parameter out of bounds
        function Test:GetInteriorVehicleDataCapabilities_ModuleTypeOutUpperBound()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = CreateModuleTypes("RADIO", 1001)
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.2.16

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
        function Test:GetInteriorVehicleDataCapabilities_InvalidJson()
          self.mobileSession.correlationId = self.mobileSession.correlationId + 1

          local msg =
          {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 0,
          rpcFunctionId    = 100016,
          rpcCorrelationId = self.mobileSession.correlationId,
          payload          = '{"zone":{"colspan":1,"row":1,"rowspan":1,"col":1,"levelspan":1,"level":1},"moduleType":{"CLIMATE" "RADIO"}}'
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
      --Description: GetInteriorVehicleDataCapabilities with all parameters of wrong type
        function Test:GetInteriorVehicleDataCapabilities_AllParamsWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {111, 111}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.2
      --Description: GetInteriorVehicleDataCapabilities with Colspan parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ColspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.3
      --Description: GetInteriorVehicleDataCapabilities with row parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_RowWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.4
      --Description: GetInteriorVehicleDataCapabilities with rowspan parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_RowspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.5
      --Description: GetInteriorVehicleDataCapabilities with col parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ColWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.6
      --Description: GetInteriorVehicleDataCapabilities with levelspan parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_LevelspanWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.7
      --Description: GetInteriorVehicleDataCapabilities with level parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_levelWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.8
      --Description: GetInteriorVehicleDataCapabilities with moduleType parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ModuleTypeWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = 111
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.8

    -----------------------------------------------------------------------------------------


      --Begin Test case CommonRequestCheck.5.9
      --Description: GetInteriorVehicleDataCapabilities with zone parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ZoneWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "CLIMATE"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.9

      --Begin Test case CommonRequestCheck.5.10
      --Description: GetInteriorVehicleDataCapabilities with rowspan and ModuleType parameters of wrong type
        function Test:GetInteriorVehicleDataCapabilities_RowspanAndModuleTypeWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {111, "abc"}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.10

      --Begin Test case CommonRequestCheck.5.11
      --Description: GetInteriorVehicleDataCapabilities with moduleType with elements parameter of wrong type
        function Test:GetInteriorVehicleDataCapabilities_ModuleTypeElementsWrongType()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {111}
          })

          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.5.11

    -----------------------------------------------------------------------------------------

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
        function Test:GetInteriorVehicleDataCapabilities_FakeParamsInsideZone()
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
          {
            zone =
            {
              fake1 = true,
              colspan = 2,
              row = 0,
              rowspan = 2,
              col = 0,
              fake2 = 1,
              levelspan = 1,
              level = 0
            },
            moduleTypes = {"RADIO"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities",
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
          :ValidIf (function(_,data)
                    if data.params.zone.fake1 or data.params.zone.fake2 then
                      print(" --SDL sends fake parameter to HMI ")
                      for key,value in pairs(data.params.zone) do print(key,value) end
                      return false
                    else
                      return true
                    end
                  end)
                  :Timeout(2000)
        end
      --End Test case CommonRequestCheck.6.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2
      --Description: app sends RPC with fake param outside zone
        function Test:GetInteriorVehicleDataCapabilities_FakeParamsOutsideZone()
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
            fake1 = "RADIO",
            moduleTypes = {"CLIMATE"},
            fake2 = false
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities",
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
                  moduleTypes = {"CLIMATE"}
                })
          :ValidIf (function(_,data)
                    if data.params.fake1 or data.params.fake2 then
                      print(" --SDL sends fake parameter to HMI ")
                      for key,value in pairs(data.params) do print(key,value) end
                      return false
                    else
                      return true
                    end
                  end)
                  :Timeout(2000)
        end
      --End Test case CommonRequestCheck.6.2
  --End Test case CommonRequestCheck.6

    -----------------------------------------------------------------------------------------

--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end