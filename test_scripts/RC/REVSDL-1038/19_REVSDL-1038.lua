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

--=================================================BEGIN TEST CASES 19==========================================================--

  --Begin Test case ResponseFakeParamsNotification.19
  --Description:  --8. driver_allow - erroneous resultCode

    --Requirement/Diagrams id in jira:
        --Requirement
        --[Requirement][TC-09]: 8. driver_allow - erroneous resultCode

      --Begin Test case ResponseAnyErroneousResultCode
      --Description: HMI responds with any erroneous resultCode for RC.GetInteriorVehicleDataConsent (This test to [Requirement][TC-09]: 8. driver_allow - erroneous resultCode)
        function Test:GetInteriorVehicleDataConsent_ResponseAnyErroneousResultCode()
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
            buttonName = "VOLUME_UP"
          })

        --hmi side: expect RC.GetInteriorVehicleDataConsent request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "RADIO",
                  zone =
                  {
                    colspan = 2,
                    row = 0,
                    rowspan = 2,
                    col = 1,
                    levelspan = 1,
                    level = 0
                  }
                })
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleDataConsent response
            self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "ERROR", {allowed = true})

          end)


          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })
          :Timeout(3000)
        end
      --End Test case ResponseAnyErroneousResultCode
  --End Test case ResponseFakeParamsNotification.19
--=================================================BEGIN TEST CASES 19==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end