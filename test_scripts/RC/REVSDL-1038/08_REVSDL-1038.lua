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

--=================================================BEGIN TEST CASES 8==========================================================--

  --Begin Test case ResponseWrongTypeCheck.8
  --Description:  --Invalid response expected by RSDL

    --Requirement/Diagrams id in jira:
        --Requirement
        --GetInteriorVehicleDataConsent

    --Verification criteria:
        --<9.>In case RSDL sends a request following the internal processes to HMI (example: permission request), and HMI responds with one or more params of wrong type per rc-HMI_API to RSDL, RSDL must log an error and ignore the received message (meaning: not process the values from response)


      --Begin Test case ResponseWrongTypeCheck.8.1
      --Description: GetInteriorVehicleDataConsent responses with allowed wrong type
        function Test:GetInteriorVehicleDataConsent_ResponseWrongTypeAllowed()
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
            self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = "true"})

          end)

          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })
          :Timeout(3000)
        end
      --End Test case ResponseWrongTypeCheck.8.1

--=================================================END TEST CASES 8==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end