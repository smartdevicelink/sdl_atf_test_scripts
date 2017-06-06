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

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: Policies: "equipment" permissions must be checked-----------------
-------------------------- against location provided from HMI--------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--


    -------------------------FOR BACK LEFT PASSENGER ZONE----------------------------------------

      --Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:BACK LEFT Passenger)
      --Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

        function Test:ChangedLocation_Left()
          --hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
          self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
            {device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
              deviceLocation =
                {
                  colspan = 2,
                  row = 1,
                  rowspan = 2,
                  col = 0,
                  levelspan = 1,
                  level = 0
                }
            })
        end
      --End Precondition.1



      --Begin Test case CommonRequestCheck.2.1.16
      --Description: application sends ButtonPress as Not Existed and ModuleType = RADIO
        function Test:ButtonPress_NotExistedRADIO()
          local cid = self.mobileSession:SendRPC("ButtonPress",
          {
            zone =
            {
              colspan = 2,
              row = 2,
              rowspan = 2,
              col = 2,
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
                    row = 2,
                    rowspan = 2,
                    col = 2,
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
      --End Test case CommonRequestCheck.2.1.16

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end