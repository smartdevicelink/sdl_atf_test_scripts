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

--=================================================BEGIN TEST CASES 17==========================================================--

  --Begin Test case ResponseFakeParamsNotification.17
  --Description:  --Fake params

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --<18.>In case a mobile app sends a valid request to RSDL, RSDL transfers this request to HMI, and HMI responds with one or more fake params (that is, non-existent per HMI_API) to RSDL, RSDL must cut these fake params off and transfer the response to the mobile app
              --Information: applicable RPCs:
              --GetInteriorVehicleDataCapabilities
              --GetInteriorVehicleData
              --SetInteriorVehicleData

      --Begin Test case case ResponseFakeParamsNotification.17.1
      --Description: GetInteriorVehicleDataCapabilities response with fake params
        function Test:GetInteriorVehicleDataCapabilities_ResposeFakeParams()
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
            moduleTypes = {"RADIO"}
          })

          --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
          EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
            interiorVehicleDataCapabilities = {
            {
            moduleZone = {
                fake1 = true,
                colspan = 2,
                row = 0,
                fake2 = 123,
                rowspan = 2,
                col = 0,
                fake3 = {1},
                levelspan = 1,
                level = 0
              },
              moduleType = "RADIO"
            }
            }
            })
          end)

          --mobile side: SDL returns SUCCESS and cuts fake params
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
          :ValidIf (function(_,data)
            --for key,value in pairs(data.payload.interiorVehicleDataCapabilities[1].moduleZone) do print(key,value) end

              if data.payload.interiorVehicleDataCapabilities[1].moduleZone.fake1 or data.payload.interiorVehicleDataCapabilities[1].moduleZone.fake2 or data.payload.interiorVehicleDataCapabilities[1].moduleZone.fake3 then
                print(" SDL resend fake parameter to mobile app ")
                for key,value in pairs(data.payload.interiorVehicleDataCapabilities[1].moduleZone) do print(key,value) end
                return false
              else
                return true
              end
          end)
        end
      --End Test case case ResponseFakeParamsNotification.17.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseFakeParamsNotification.17.2
      --Description: SetInteriorVehicleData response with fake params
        function Test:SetInteriorVehicleData_ResposeFakeParamsInsideModuleData()
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
                    fake1 = true,
                    colspan = 2,
                    row = 0,
                    rowspan = 2,
                    fake2 = 123,
                    col = 0,
                    levelspan = 1,
                    level = 0,
                    fake3 = " a b c "
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

          --mobile side: SDL returns SUCCESS and cuts fake params
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
          :ValidIf (function(_,data)
            --for key,value in pairs(data.payload.moduleData.moduleZone) do print(key,value) end
              if data.payload.moduleData.moduleZone.fake1 or data.payload.moduleData.moduleZone.fake2 or data.payload.moduleData.moduleZone.fake3 then
                print(" SDL resend fake parameter to mobile app ")
                for key,value in pairs(data.payload.moduleData.moduleZone) do print(key,value) end
                return false
              else
                return true
              end
          end)
        end
      --End Test case ResponseFakeParamsNotification.17.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseFakeParamsNotification.17.3
      --Description: SetInteriorVehicleData response with fake params
        function Test:SetInteriorVehicleData_ResposeFakeParamsOutsideModuleData()
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
                fake1 = true,
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
                },
                fake2 = {1},
                fake3 = " fake parameters   "
              })
            end)

          --mobile side: SDL returns SUCCESS and cuts fake params
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
          :ValidIf (function(_,data)
            --for key,value in pairs(data.payload) do print(key,value) end

              if data.payload.fake1 or data.payload.fake2 or data.payload.fake3 then
                print(" SDL resend fake parameter to mobile app ")
                for key,value in pairs(data.payload) do print(key,value) end
                return false
              else
                return true
              end
          end)
        end
      --End Test case ResponseFakeParamsNotification.17.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseFakeParamsNotification.17.4
      --Description: GetInteriorVehicleData response with fake params
        function Test:GetInteriorVehicleData_ResposeFakeParamsInsideModuleData()
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
                  moduleData =
                  {
                    radioControlData =
                    {
                      fake1 = true,
                      radioEnable = true,
                      frequencyInteger = 105,
                      frequencyFraction = 3,
                      band = "AM",
                      hdChannel = 1,
                      state = "ACQUIRED",
                      availableHDs = 1,
                      signalStrength = 50,
                      rdsData =
                      {
                        fake2 = {1},
                        PS = "12345678",
                        RT = "Radio text minlength = 0, maxlength = 64",
                        CT = "2015-09-29T18:46:19-0700",
                        PI = "PIdent",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = "don't mention min,max length"
                      },
                      signalChangeThreshold = 10
                    },
                    moduleType = "RADIO",
                    moduleZone =
                    {
                      fake3 = " fake params  ",
                      colspan = 2,
                      row = 0,
                      rowspan = 2,
                      col = 0,
                      levelspan = 1,
                      level = 0
                    }
                  }
              })
            end)

          --mobile side: SDL returns SUCCESS and cuts fake params
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
          :ValidIf (function(_,data)
            --for key,value in pairs(data.payload.moduleData) do print(key,value) end

              if data.payload.moduleData.radioControlData.fake1 or data.payload.moduleData.radioControlData.rdsData.fake2 or data.payload.moduleData.moduleZone.fake3 then
                print(" SDL resend fake parameter to mobile app ")
                for key,value in pairs(data.payload.moduleData.radioControlData) do print(key,value) end
                return false
              else
                return true
              end
          end)
        end
      --End Test case ResponseFakeParamsNotification.17.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseFakeParamsNotification.17.5
      --Description: GetInteriorVehicleData response with fake params
        function Test:GetInteriorVehicleData_ResposeFakeParamsOutsideModuleData()
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
                  fake1 = {1},
                  moduleData =
                  {
                    fake2 = true,
                    radioControlData =
                    {
                      radioEnable = true,
                      frequencyInteger = 105,
                      frequencyFraction = 3,
                      band = "AM",
                      hdChannel = 1,
                      state = "ACQUIRED",
                      availableHDs = 1,
                      signalStrength = 50,
                      rdsData =
                      {
                        PS = "12345678",
                        RT = "Radio text minlength = 0, maxlength = 64",
                        CT = "2015-09-29T18:46:19-0700",
                        PI = "PIdent",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = "don't mention min,max length"
                      },
                      signalChangeThreshold = 10
                    },
                    moduleType = "RADIO",
                    moduleZone =
                    {
                      colspan = 2,
                      row = 0,
                      rowspan = 2,
                      col = 0,
                      levelspan = 1,
                      level = 0
                    }
                  },
                  fake3 = " fake params "
              })
            end)

          --mobile side: SDL returns SUCCESS and cuts fake params
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
          :ValidIf (function(_,data)
            --for key,value in pairs(data.payload.moduleData) do print(key,value) end

              if data.payload.fake1 or data.payload.moduleData.fake2 or data.payload.fake3 then
                print(" SDL resend fake parameter to mobile app ")
                for key,value in pairs(data.payload) do print(key,value) end
                return false
              else
                return true
              end
          end)
        end
      --End Test case ResponseFakeParamsNotification.17.5

  --End Test case ResponseFakeParamsNotification.17
--=================================================END TEST CASES 17==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end