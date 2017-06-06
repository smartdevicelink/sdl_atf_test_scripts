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

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
-----------Requirement: Validation: RPC with mismatched control-params and-------------------
----------------------moduleType from mobile app must get INVALID_DATA-----------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test suit CommonRequestCheck.2 for Req.#2

  --Description: 2. In case application registered with REMOTE_CONTROL AppHMIType sends ButtonPress RPC with <radio-related-buttons> and CLIMATE moduleType
              --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.

  --Begin Test case CommonRequestCheck.2.1
  --Description:  RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --In case application registered with REMOTE_CONTROL AppHMIType sends ButtonPress RPC with <radio-related-buttons> and CLIMATE moduleType

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.1
      --Description: application sends ButtonPress with ModuleType = CLIMATE, buttonName = VOLUME_UP
        function Test:ButtonPress_CLIMATE_SHORT()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "VOLUME_UP"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.2.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.2
      --Description: application sends ButtonPress with ModuleType = CLIMATE, buttonName = VOLUME_DOWN
        function Test:ButtonPress_CLIMATE_VOLUMEDOWN()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "VOLUME_DOWN"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.2.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.3
      --Description: application sends ButtonPress with ModuleType = CLIMATE, buttonName = EJECT
        function Test:ButtonPress_CLIMATE_EJECT()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "EJECT"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.2.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.4
      --Description: application sends ButtonPress with ModuleType = CLIMATE, buttonName = SOURCE
        function Test:ButtonPress_CLIMATE_SOURCE()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "SOURCE"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.2.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.5
      --Description: application sends ButtonPress with ModuleType = CLIMATE, buttonName = SHUFFLE
        function Test:ButtonPress_CLIMATE_SHUFFLE()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "SHUFFLE"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.2.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.6
      --Description: application sends ButtonPress with ModuleType = CLIMATE, buttonName = REPEAT
        function Test:ButtonPress_CLIMATE_REPEAT()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "REPEAT"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.2.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.7
      --Description: application sends ButtonPress as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE, ButtonName=VOLUME_UP
        function Test:ButtonPress_LeftCLIMATE_VOLUMEUP()
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
            buttonName = "VOLUME_UP"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.2.1.7

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.2.1


--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end