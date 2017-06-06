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


--=================================================BEGIN TEST CASES 1==========================================================--
  --Begin Test suit CommonRequestCheck.1 for Req.#1

  --Description: 1. In case application registered with REMOTE_CONTROL AppHMIType sends ButtonPress RPC with <climate-related-buttons> and RADIO moduleType
              --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.

  --Begin Test case CommonRequestCheck.1.1
  --Description:  RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --In case application registered with REMOTE_CONTROL AppHMIType sends ButtonPress RPC with <climate-related-buttons> and RADIO moduleType

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.1
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = AC_MAX
        function Test:ButtonPress_RADIO_ACMAX()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "AC_MAX"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.2
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = AC
        function Test:ButtonPress_RADIO_AC()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "AC"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.3
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = RECIRCULATE
        function Test:ButtonPress_RADIO_RECIRCULATE()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "RECIRCULATE"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.4
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = FAN_UP
        function Test:ButtonPress_RADIO_FANUP()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "FAN_UP"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.5
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = FAN_DOWN
        function Test:ButtonPress_RADIO_FANDOWN()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "FAN_DOWN"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.6
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = TEMP_UP
        function Test:ButtonPress_RADIO_TEMPUP()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "TEMP_UP"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.7
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = TEMP_DOWN
        function Test:ButtonPress_RADIO_TEMPDOWN()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "TEMP_DOWN"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.8
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = DEFROST_MAX
        function Test:ButtonPress_RADIO_DEFROSTMAX()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "DEFROST_MAX"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.9
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = DEFROST
        function Test:ButtonPress_RADIO_DEFROST()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "DEFROST"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.10
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = DEFROST_REAR
        function Test:ButtonPress_RADIO_DEFROSTREAR()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "DEFROST_REAR"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.11
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = UPPER_VENT
        function Test:ButtonPress_RADIO_UPPERVENT()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "UPPER_VENT"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.11

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.12
      --Description: application sends ButtonPress with ModuleType = RADIO, buttonName = LOWER_VENT
        function Test:ButtonPress_RADIO_LOWERVENT()
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "LOWER_VENT"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
        end
      --End Test case CommonRequestCheck.1.1.12

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.13
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO, ButtonName = DEFROST_REAR
        function Test:ButtonPress_FrontRADIO_DEFROSTREAR()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 2,
              row = 0,
              rowspan = 2,
              col = 1,
              levelspan = 1,
              level = 0
            },
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "DEFROST_REAR"
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("Buttons.ButtonPress")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.1.1.13

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.1.1


--=================================================END TEST CASES 1==========================================================--


function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end