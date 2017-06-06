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

--=================================================BEGIN TEST CASES 3==========================================================--
  --Begin Test suit CommonRequestCheck.3 for Req.#3

  --Description: 3. In case application registered with REMOTE_CONTROL AppHMIType sends SetInteriorVehicleData RPC with "climateControlData" and RADIO moduleType
              -- RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.

  --Begin Test case CommonRequestCheck.3.1
  --Description:  RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --In case application registered with REMOTE_CONTROL AppHMIType sends SetInteriorVehicleData RPC with "climateControlData" and RADIO moduleType

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.1
      --Description: application sends SetInteriorVehicleData as Driver and ModuleType = RADIO
        function Test:SetInterior_RADIO_WrongControlData()
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

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.3.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.3.1.2
      --Description: application sends SetInteriorVehicleData as Front Passenger and ModuleType = RADIO
        function Test:SetInterior_RADIO_FrontClimateControlData()
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
                row = 0,
                rowspan = 2
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

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.3.1.2

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.3.1


--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end