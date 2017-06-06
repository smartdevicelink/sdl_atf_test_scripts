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

--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
-----------Requirement: "Allow", "Ask Driver" or "Disallow" permissions - depending-----------
------------------on zone value in RPC and this zone permissions in Policies-----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

---------------------NOTE: THIS SCRIPT ONLY TEST FOR PASSENGER'S DEVICE----------------------

--=================================================BEGIN TEST CASES 1==========================================================--
  --Begin Test suit CommonRequestCheck.1 for Req.#1

  --Description: 1. In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "auto_allow" sub-section of <interiorZone> section - RSDL must send this RPC with these <params> to the vehicle (HMI).


  --Begin Test case CommonRequestCheck.1.1
  --Description:  For ButtonPress

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "auto_allow" sub-section of <interiorZone> section - RSDL must send this RPC with these <params> to the vehicle (HMI).

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.1
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonPressMode = LONG
        function Test:ButtonPress_AutoAllowDriverRADIO_ButtonPressMode_LONG()
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
            buttonName = "VOLUME_UP"
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
                  moduleType = "RADIO",
                  buttonPressMode = "LONG",
                  buttonName = "VOLUME_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.2
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonPressMode = SHORT
        function Test:ButtonPress_AutoAllowDriverRADIO_ButtonPressMode_SHORT()
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
            buttonPressMode = "SHORT",
            buttonName = "VOLUME_UP"
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
                  moduleType = "RADIO",
                  buttonPressMode = "SHORT",
                  buttonName = "VOLUME_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.3
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonName = VOLUME_UP
        function Test:ButtonPress_AutoAllowDriverRADIO_ButtonName_VOLUME_UP()
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
            buttonPressMode = "SHORT",
            buttonName = "VOLUME_UP"
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
                  moduleType = "RADIO",
                  buttonPressMode = "SHORT",
                  buttonName = "VOLUME_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.4
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonName = VOLUME_DOWN
        function Test:ButtonPress_AutoAllowDriverRADIO_ButtonName_VOLUME_DOWN()
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
            buttonPressMode = "SHORT",
            buttonName = "VOLUME_DOWN"
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
                  moduleType = "RADIO",
                  buttonPressMode = "SHORT",
                  buttonName = "VOLUME_DOWN"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.5
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonName = EJECT
        function Test:ButtonPress_AutoAllowDriverRADIO_ButtonName_EJECT()
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
            buttonPressMode = "SHORT",
            buttonName = "EJECT"
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
                  moduleType = "RADIO",
                  buttonPressMode = "SHORT",
                  buttonName = "EJECT"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.6
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonName = SOURCE
        function Test:ButtonPress_AutoAllowDriverRADIO_ButtonName_SOURCE()
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
            buttonPressMode = "SHORT",
            buttonName = "SOURCE"
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
                  moduleType = "RADIO",
                  buttonPressMode = "SHORT",
                  buttonName = "SOURCE"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.7
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonName = SHUFFLE
        function Test:ButtonPress_AutoAllowDriverRADIO_ButtonName_SHUFFLE()
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
            buttonPressMode = "SHORT",
            buttonName = "SHUFFLE"
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
                  moduleType = "RADIO",
                  buttonPressMode = "SHORT",
                  buttonName = "SHUFFLE"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.8
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonName = REPEAT
        function Test:ButtonPress_AutoAllowDriverRADIO_ButtonName_REPEAT()
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
            buttonPressMode = "SHORT",
            buttonName = "REPEAT"
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
                  moduleType = "RADIO",
                  buttonPressMode = "SHORT",
                  buttonName = "REPEAT"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.9
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonPressMode = LONG
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonPressMode_LONG()
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
      --End Test case CommonRequestCheck.1.1.9

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.10
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonPressMode = SHORT
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonPressMode_SHORT()
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
                  buttonPressMode = "SHORT",
                  buttonName = "AC_MAX"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.10

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.11
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = AC_MAX
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_AC_MAX()
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
                  buttonPressMode = "SHORT",
                  buttonName = "AC_MAX"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.11

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.12
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = AC
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_AC()
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
            buttonName = "AC"
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
                  buttonPressMode = "SHORT",
                  buttonName = "AC"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.12

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.13
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = RECIRCULATE
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_RECIRCULATE()
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
            buttonName = "RECIRCULATE"
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
                  buttonPressMode = "SHORT",
                  buttonName = "RECIRCULATE"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.13

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.14
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = FAN_UP
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_FAN_UP()
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
            buttonName = "FAN_UP"
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
                  buttonPressMode = "SHORT",
                  buttonName = "FAN_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.14

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.15
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = FAN_DOWN
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_FAN_DOWN()
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
            buttonName = "FAN_DOWN"
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
                  buttonPressMode = "SHORT",
                  buttonName = "FAN_DOWN"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.15

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.16
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = TEMP_UP
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_TEMP_UP()
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
            buttonName = "TEMP_UP"
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
                  buttonPressMode = "SHORT",
                  buttonName = "TEMP_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.16

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.17
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = TEMP_DOWN
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_TEMP_DOWN()
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
            buttonName = "TEMP_DOWN"
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
                  buttonPressMode = "SHORT",
                  buttonName = "TEMP_DOWN"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.17

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.18
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = DEFROST_MAX
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_DEFROST_MAX()
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
            buttonName = "DEFROST_MAX"
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
                  buttonPressMode = "SHORT",
                  buttonName = "DEFROST_MAX"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.18

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.19
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = DEFROST
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_DEFROST()
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
            buttonName = "DEFROST"
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
                  buttonPressMode = "SHORT",
                  buttonName = "DEFROST"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.19

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.20
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = DEFROST_REAR
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_DEFROST_REAR()
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
            buttonName = "DEFROST_REAR"
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
                  buttonPressMode = "SHORT",
                  buttonName = "DEFROST_REAR"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.20

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.21
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = UPPER_VENT
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_UPPER_VENT()
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
            buttonName = "UPPER_VENT"
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
                  buttonPressMode = "SHORT",
                  buttonName = "UPPER_VENT"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.21

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.22
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE, buttonName = LOWER_VENT
        function Test:ButtonPress_AutoAllowDriverCLIMATE_ButtonName_LOWER_VENT()
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
            buttonName = "LOWER_VENT"
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
                  buttonPressMode = "SHORT",
                  buttonName = "LOWER_VENT"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.22

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.23
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonPressMode = LONG
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonPressMode_LONG()
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
                    col = 1,
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
      --End Test case CommonRequestCheck.1.1.23

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.24
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonPressMode = SHORT
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonPressMode_SHORT()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
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
                    col = 1,
                    levelspan = 1,
                    level = 0
                  },
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "AC_MAX"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.24

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.25
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = AC_MAX
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_AC_MAX()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
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
                    col = 1,
                    levelspan = 1,
                    level = 0
                  },
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "AC_MAX"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.25

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.26
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = AC
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_AC()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "AC"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "AC"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.26

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.27
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = RECIRCULATE
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_RECIRCULATE()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "RECIRCULATE"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "RECIRCULATE"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.27

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.28
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = FAN_UP
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_FAN_UP()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "FAN_UP"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "FAN_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.28

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.29
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = FAN_DOWN
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_FAN_DOWN()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "FAN_DOWN"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "FAN_DOWN"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.29

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.30
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = TEMP_UP
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_TEMP_UP()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "TEMP_UP"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "TEMP_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.30

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.31
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = TEMP_DOWN
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_TEMP_DOWN()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "TEMP_DOWN"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "TEMP_DOWN"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.31

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.32
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = DEFROST_MAX
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_DEFROST_MAX()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "DEFROST_MAX"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "DEFROST_MAX"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.32

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.33
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = DEFROST
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_DEFROST()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "DEFROST"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "DEFROST"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.33

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.34
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = DEFROST_REAR
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_DEFROST_REAR()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "DEFROST_REAR"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "DEFROST_REAR"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.34

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.35
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = UPPER_VENT
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_UPPER_VENT()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "UPPER_VENT"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "UPPER_VENT"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.35

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.36
      --Description: application sends ButtonPress as front passenger and ModuleType = CLIMATE, buttonName = LOWER_VENT
        function Test:ButtonPress_AutoAllowFrontCLIMATE_ButtonName_LOWER_VENT()
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
            moduleType = "CLIMATE",
            buttonPressMode = "SHORT",
            buttonName = "LOWER_VENT"
          })

        --hmi side: expect Buttons.ButtonPress request
        EXPECT_HMICALL("Buttons.ButtonPress",
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
                  moduleType = "CLIMATE",
                  buttonPressMode = "SHORT",
                  buttonName = "LOWER_VENT"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.36

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.1.37
      --Description: application sends ButtonPress as Left Rare Passenger (col=0/ row=1/ level=0) and ModuleType = RADIO, buttonName = SHUFFLE
        function Test:ButtonPress_AutoAllowLeftRADIO()
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
            moduleType = "RADIO",
            buttonPressMode = "SHORT",
            buttonName = "SHUFFLE"
          })

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
                  moduleType = "RADIO",
                  buttonPressMode = "SHORT",
                  buttonName = "SHUFFLE"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.1.1.37

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.1.1


  --Begin Test case CommonRequestCheck.1.2
  --Description:  For GetInteriorVehicleData

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "auto_allow" sub-section of <interiorZone> section - RSDL must send this RPC with these <params> to the vehicle (HMI).

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.2.1
      --Description: application sends GetInteriorVehicleData as Driver and ModuleType = RADIO
        function Test:GetInterior_AutoDriverRADIO()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
      --End Test case CommonRequestCheck.1.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.2.2
      --Description: application sends GetInteriorVehicleData as Driver and ModuleType = CLIMATE
        function Test:GetInterior_AutoDriverCLIMATE()
          --mobile sends request for precondition
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
                    temperatureUnit = "CELSIUS"
                  }
                }
              })
            end)

          --mobile side: expect SUCCESS response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case CommonRequestCheck.1.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.2.3
      --Description: application sends GetInteriorVehicleData as Front Passenger (col=1/ row=0/ level=0) and ModuleType = CLIMATE
        function Test:GetInterior_AutoFrontCLIMATE()
          --mobile sends request for precondition
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
                col = 1,
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
                    col = 1,
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

          --mobile side: expect SUCCESS response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case CommonRequestCheck.1.2.3

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.1.2



  --Begin Test case CommonRequestCheck.1.3
  --Description:  For SetInteriorVehicleData

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "auto_allow" sub-section of <interiorZone> section - RSDL must send this RPC with these <params> to the vehicle (HMI).

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.3.1
      --Description: application sends SetInteriorVehicleData as Driver and ModuleType = RADIO
        function Test:SetInterior_AutoDriverRADIO()
          --mobile sends request for precondition
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
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
      --End Test case CommonRequestCheck.1.3.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.3.2
      --Description: application sends SetInteriorVehicleData as Driver and ModuleType = CLIMATE
        function Test:SetInterior_AutoDriverCLIMATE()
          --mobile sends request for precondition
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
                    temperatureUnit = "CELSIUS"
                  }
                }
              })
            end)

          --mobile side: expect SUCCESS response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case CommonRequestCheck.1.3.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.3.3
      --Description: application sends GetInteriorVehicleData as Front Passenger (col=1/ row=0/ level=0) and ModuleType = CLIMATE
        function Test:SetInterior_AutoFrontCLIMATE()
          --mobile sends request for precondition
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
                col = 1,
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
                    col = 1,
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

          --mobile side: expect SUCCESS response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case CommonRequestCheck.1.3.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.1.3.4
      --Description: application sends GetInteriorVehicleData as Right Rare Passenger (col=1/ row=1/ level=0) and ModuleType = RADIO
        function Test:SetInterior_AutoRightRADIO()
          --mobile sends request for precondition
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData = {
              moduleType = "RADIO",
              moduleZone = {
                col = 1,
                colspan = 2,
                level = 0,
                levelspan = 1,
                row = 1,
                rowspan = 2
              },
              radioControlData = {
                frequencyInteger = 99
                },
                availableHDs = 3,
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
          })

          --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
          :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                  moduleData = {
                    moduleType = "RADIO",
                    moduleZone = {
                      col = 1,
                      colspan = 2,
                      level = 0,
                      levelspan = 1,
                      row = 1,
                      rowspan = 2
                    },
                    radioControlData = {
                      frequencyInteger = 99
                      },
                      availableHDs = 3,
                      hdChannel = 1,
                      signalStrength = 50,
                      signalChangeThreshold = 60,
                      radioEnable = true,
                      state = "ACQUIRING"
                    }
              })

            end)

            --mobile side: expect SUCCESS response
            EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case CommonRequestCheck.1.3.4

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.1.3

--=================================================END TEST CASES 1==========================================================--


function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end