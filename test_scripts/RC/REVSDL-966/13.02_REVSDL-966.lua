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
--=================================================BEGIN TEST CASES 13==========================================================--

  --Begin Test case CommonRequestCheck.13.2
  --Description:  For GetInteriorVehicleData

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.13.2.1
      --Description: application sends GetInteriorVehicleData as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO (first time, asking driver's permission)
        function Test:GetInterior_FrontRADIO()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
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
                col = 1,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
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
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                      moduleData = {
                        moduleType = "RADIO",
                        moduleZone = {
                          col = 1,
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
          end)

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.13.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.13.2.2
      --Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO (the second, asking new permission and HMI auto REJECTED)
        function Test:GetInterior_LeftRADIO()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "RADIO",
              moduleZone =
              {
                colspan = 2,
                row = 1,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0,
              }
            },
            subscribe = true
          })

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application"],
                  moduleType = "RADIO",
                  zone =
                  {
                    colspan = 2,
                    row = 1,
                    rowspan = 2,
                    col = 0,
                    levelspan = 1,
                    level = 0
                  }
          })
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL and HMI auto reject this request.
            self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"error":{"code":4,"message":"Already consented!","data":{"method":"RC.GetInteriorVehicleDataConsent"}}}')

          end)

          --RSDL must respond with "resultCode: USER_DISALLOWED, success: false
          EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })
        end
      --End Test case CommonRequestCheck.13.2.2

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.13.2

--=================================================END TEST CASES 13==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
