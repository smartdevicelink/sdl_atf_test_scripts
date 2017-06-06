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

--=================================================BEGIN TEST CASES 13==========================================================--

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

      --Begin Test case Precondition.1
      --Description: mobile sends GetInteriorVehicleData request with subscribe = true for precondtion
        function Test:OnInteriorVehicleData_Precondition_RADIO()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
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
      --End Test case Precondition.1

      --Begin Test case Precondition.2
      --Description: GetInteriorVehicleData response with subscribe = true for precondtion
        function Test:GetInteriorVehicleData_Precondition_CLIMATE()
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
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

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

        end
      --End Test case Precondition.2

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

  --Begin Test case ResponseInvalidJsonNotification.13
  --Description:  --Invalid notification

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --<14.>In case HMI sends a notification of invalid JSON to RSDL, RSDL must log an error and ignore this notification.

      --Begin Test case ResponseInvalidJsonNotification.13.1
      --Description: OnInteriorVehicleData with wrong json
        function Test:OnInteriorVehicleData_WrongJson()

              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:Send('{"jsonrpc":"2.0","method":"RC.OnInteriorVehicleData","params":{"moduleData":{"moduleType":"CLIMATE","moduleZone":{"col":0,"row":0,"level":0,"colspan":2,"rowspan":2,"levelspan":1},"climateControlData":{"fanSpeed":50,"currentTemp":86,"desiredTemp":75,"temperatureUnit":"FAHRENHEIT","acEnable":true,"circulateAirEnable":true,"autoModeEnable":true,"defrostZone":"FRONT","dualModeEnable" true}}}}')

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)


        end
      --End Test case ResponseInvalidJsonNotification.13.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseInvalidJsonNotification.13.2
      --Description: OnSetDriversDevice with wrong json
        function Test:OnSetDriversDevice_WrongJson()
          --hmi side: sending RC.OnSetDriversDevice notification
          self.hmiConnection:Send('{"jsonrpc":"2.0","method":"RC.OnSetDriversDevice","params":{"device":{"name":"10.42.0.73","id":1,"isSDLAllowed" false}}}')

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)
        end
      --End Test case ResponseInvalidJsonNotification.13.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseInvalidJsonNotification.13.3
      --Description: OnReverseAppsAllowing with wrong json
        function Test:OnReverseAppsAllowing_WrongJson()
          --hmi side: sending RC.OnReverseAppsAllowing notification
          self.hmiConnection:Send('{"jsonrpc":"2.0","method":"RC.OnReverseAppsAllowing","params":{"allowed" false}}')

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(0)
        end
      --End Test case ResponseInvalidJsonNotification.13.3

  --End Test case ResponseInvalidJsonNotification.13
--=================================================END TEST CASES 13==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end