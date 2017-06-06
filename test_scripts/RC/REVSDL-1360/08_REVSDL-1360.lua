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


--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
-----------------Requirement: VehicleData subscriptions handling by RSDL --------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 8==========================================================--
  --Begin Test suit CommonRequestCheck.8 for Req.#8

  --Description: 8. In case mobile application with REMOTE_CONTROL appHMIType subscribed to "<moduleZone_value>, <moduleType_value>" sends GetInteriorVehicleData with ("subscribe: true", <moduleZone_value>, <moduleType_value>), RSDL must keep this application subscribed for requested <moduleType_value> in requested <moduleZone_value>.


  --Begin Test case CommonRequestCheck.8.2 (stop SDL before running this test suite)
  --Description:  PASSENGER's Device: In case mobile application with REMOTE_CONTROL appHMIType subscribed to "<moduleZone_value>, <moduleType_value>" sends GetInteriorVehicleData with ("subscribe: true", <moduleZone_value>, <moduleType_value>), RSDL must keep this application subscribed for requested <moduleType_value> in requested <moduleZone_value>.

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --RSDL subscribes the RC-app to interiorVehicleData notifications right after getting "subscribe:true" from the app

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.8.2.0
      --Description: --Set device to Passenger's device
        function Test:NonSubscription_SetPassengerDevice()
          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "PASSENGER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for passenger's device
          --EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )

        end
      --End Test case CommonRequestCheck.8.2.0

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.8.2.1
      --Description: --1. Application sends GetInteriorVehicleData as Zone = Driver and ModuleType = CLIMATE
               --2. HMI sends OnInteriorVehicleData notification to RSDL
        function Test:NonSubscription_PassengerDriverCLIMATE()
          --mobile sends request for precondition as Driver
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

              --hmi side: HMI sends OnInteriorVehicleData notification to RSDL
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
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
                    fanSpeed = 51,
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

          --mobile side: RSDL sends notifications to mobile app
          EXPECT_NOTIFICATION("OnInteriorVehicleData")
          :Times(1)

        end
      --End Test case CommonRequestCheck.8.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.8.2.2
      --Description: --1. Application sends GetInteriorVehicleData as Zone = Front Passenger and ModuleType = CLIMATE
               --2. HMI sends OnInteriorVehicleData notification to RSDL
        function Test:NonSubscription_PassengerFrontCLIMATE()
          --mobile sends request for precondition as Front Passenger
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
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
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

              --hmi side: HMI sends OnInteriorVehicleData notification to RSDL
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
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
                    fanSpeed = 51,
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

          --mobile side: RSDL sends notifications to mobile app
          EXPECT_NOTIFICATION("OnInteriorVehicleData")
          :Times(1)

        end
      --End Test case CommonRequestCheck.8.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.8.2.3
      --Description: --1. Application sends GetInteriorVehicleData as Zone = Left Rare Passenger and ModuleType = CLIMATE
               --2. HMI sends OnInteriorVehicleData notification to RSDL
        function Test:NonSubscription_PassengerLeftCLIMATE()
          --mobile side: --mobile sends request for precondition as Left Rare Passenger
          local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
          {
            moduleDescription =
            {
              moduleType = "CLIMATE",
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
                  moduleType = "CLIMATE",
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
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data1)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", { isSubscribed = true,
                    moduleData =
                    {
                      moduleType = "CLIMATE",
                      moduleZone =
                      {
                        colspan = 2,
                        row = 1,
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

                  --hmi side: HMI sends OnInteriorVehicleData notification to RSDL
                  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                    moduleData =
                    {
                      moduleType = "CLIMATE",
                      moduleZone =
                      {
                        colspan = 2,
                        row = 1,
                        rowspan = 2,
                        col = 0,
                        levelspan = 1,
                        level = 0
                      },
                      climateControlData =
                      {
                        fanSpeed = 50,
                        circulateAirEnable = false,
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
          end)



          --mobile side: expect SUCCESS response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

          --mobile side: RSDL sends notifications to mobile app
          EXPECT_NOTIFICATION("OnInteriorVehicleData")
          :Times(1)

        end
      --End Test case CommonRequestCheck.8.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.8.2.4
      --Description: --1. Application sends GetInteriorVehicleData as Zone = Driver and ModuleType = RADIO
               --2. HMI sends OnInteriorVehicleData notification to RSDL
        function Test:NonSubscription_PassengerDriverRADIO()
          --mobile sends request for precondition as Driver
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

              --hmi side: HMI sends OnInteriorVehicleData notification to RSDL
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
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
                    band = "AM",
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



          --mobile side: expect SUCCESS response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

          --mobile side: RSDL sends notifications to mobile app
          EXPECT_NOTIFICATION("OnInteriorVehicleData")
          :Times(1)

        end
      --End Test case CommonRequestCheck.8.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.8.2.5
      --Description: --1. Application sends GetInteriorVehicleData as Zone = Front Passenger and ModuleType = RADIO
               --2. HMI sends OnInteriorVehicleData notification to RSDL
        function Test:NonSubscription_PassengerFrontRADIO()
          --mobile sends request for precondition as Front Passenger
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
                :Do(function(_,data1)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", { isSubscribed = true,
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

                  --hmi side: HMI sends OnInteriorVehicleData notification to RSDL
                  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
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
                        band = "AM",
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


          --mobile side: expect SUCCESS response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

          --mobile side: RSDL sends notifications to mobile app
          EXPECT_NOTIFICATION("OnInteriorVehicleData")
          :Times(1)

        end
      --End Test case CommonRequestCheck.8.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.8.2.6
      --Description: --1. Application sends GetInteriorVehicleData as Zone = Left Rare Passenger and ModuleType = RADIO
               --2. HMI sends OnInteriorVehicleData notification to RSDL
        function Test:NonSubscription_PassengerLeftRADIO()
          --mobile sends request for precondition as Left Rare Passenger
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
              --hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
              self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

              --hmi side: expect RC.GetInteriorVehicleData request
              EXPECT_HMICALL("RC.GetInteriorVehicleData")
              :Do(function(_,data1)
                  --hmi side: sending RC.GetInteriorVehicleData response
                  self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", { isSubscribed = true,
                    moduleData = {
                      moduleType = "RADIO",
                      moduleZone = {
                        col = 0,
                        colspan = 2,
                        level = 0,
                        levelspan = 1,
                        row = 1,
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

                  --hmi side: HMI sends OnInteriorVehicleData notification to RSDL
                  self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                    moduleData = {
                      moduleType = "RADIO",
                      moduleZone = {
                        col = 0,
                        colspan = 2,
                        level = 0,
                        levelspan = 1,
                        row = 1,
                        rowspan = 2
                      },
                      radioControlData = {
                        frequencyInteger = 99,
                        frequencyFraction = 3,
                        band = "AM",
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


          --mobile side: expect SUCCESS response with info
          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

          --mobile side: RSDL sends notifications to mobile app
          EXPECT_NOTIFICATION("OnInteriorVehicleData")
          :Times(1)

        end
      --End Test case CommonRequestCheck.8.2.6

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.8.2

--=================================================END TEST CASES 8==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
