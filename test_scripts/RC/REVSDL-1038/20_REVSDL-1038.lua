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

--=================================================BEGIN TEST CASES 20==========================================================--

  --Begin Test case MaxlengthREG.20
  --Description:  --APP's, HMI's RPCs Validation: should we set Maxlength for "REG" param?

    --Requirement/Diagrams id in jira:
        --Requirement (Question)
        --minlength="0" maxlength=”255"

      --Begin Test case MaxlengthREG.20.1
      --Description: mobile sends GetInteriorVehicleData request with subscribe = true and HMI responds upper bound for REG (256)
        function Test:GetInteriorVehicleData_Response_UpperBoundREG()
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
                        REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tune"
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
      --End Test case MaxlengthREG.20.1

    -----------------------------------------------------------------------------------------

      --Begin Test case MaxlengthREG.20.2
      --Description: mobile sends GetInteriorVehicleData request with subscribe = true and HMI responds out upper bound for REG (257)
        function Test:GetInteriorVehicleData_Response_OutUpperBoundREG()
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
                        REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tunez"
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

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})

        end
      --End Test case MaxlengthREG.20.2

    -----------------------------------------------------------------------------------------

      --Begin Test case MaxlengthREG.20.3
      --Description: mobile sends SetInteriorVehicleData request and HMI responds upper bound for REG (256)
        function Test:SetInteriorVehicleData_Response_UpperBoundREG()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
                  moduleData =
                  {
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
                        RT = "",
                        CT = "123456789012345678901234",
                        PI = "",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = ""
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
                  }
          })

          --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                  moduleData =
                  {
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
                        RT = "",
                        CT = "123456789012345678901234",
                        PI = "",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tune"
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
                  }
              })
            end)

            --mobile side: expect SUCCESS response
            EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case MaxlengthREG.20.3

    -----------------------------------------------------------------------------------------

      --Begin Test case MaxlengthREG.20.4
      --Description: mobile sends SetInteriorVehicleData request and HMI responds out upper bound for REG (257)
        function Test:SetInteriorVehicleData_Response_OutUpperBoundREG()
          --mobile sends request for precondition
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
                  moduleData =
                  {
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
                        RT = "",
                        CT = "123456789012345678901234",
                        PI = "",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = ""
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
                  }
          })

          --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                  moduleData =
                  {
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
                        RT = "",
                        CT = "123456789012345678901234",
                        PI = "",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tunez"
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
                  }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})

        end
      --End Test case MaxlengthREG.20.4

    -----------------------------------------------------------------------------------------

      --Begin Test case MaxlengthREG.20.5
      --Description: mobile sends SetInteriorVehicleData request with upper bound for REG (256)
        function Test:SetInteriorVehicleData_UpperBoundREG()
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
                  moduleData =
                  {
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
                        RT = "",
                        CT = "123456789012345678901234",
                        PI = "",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tune"
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
                  }
          })

          --hmi side: expect RC.SetInteriorVehicleData request
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
            :Do(function(_,data)
              --hmi side: sending RC.SetInteriorVehicleData response
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                  moduleData =
                  {
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
                        RT = "",
                        CT = "123456789012345678901234",
                        PI = "",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tune"
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
                  }
              })
            end)

            --mobile side: expect SUCCESS response
            EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case MaxlengthREG.20.5

    -----------------------------------------------------------------------------------------

      --Begin Test case MaxlengthREG.20.6
      --Description: mobile sends SetInteriorVehicleData request with out upper bound for REG (257)
        function Test:SetInteriorVehicleData_OutUpperBoundREG()
          --mobile sends request for precondition
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
                  moduleData =
                  {
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
                        RT = "",
                        CT = "123456789012345678901234",
                        PI = "",
                        PTY = 0,
                        TP = true,
                        TA = false,
                        REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tunez"
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
                  }
          })


          --mobile side: expect INVALID_DATA response
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

        end
      --End Test case MaxlengthREG.20.6

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

      --Begin Test case Precondition.1
      --Description: mobile sends GetInteriorVehicleData request with subscribe = true for precondtion
        function Test:GetInteriorVehicleData_Precondition_RADIO()
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

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

      --Begin Test case MaxlengthREG.20.7
      --Description: HMI responds OnInteriorVehicleData to RSDL with upper bound for REG (256)
        function Test:OnInteriorVehicleData_UpperBoundREG()
              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          state = "ACQUIRED",
                          hdChannel = 1,
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tune"
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
                      }
              })

              --mobile side: receiving of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(1)
        end
      --End Test case MaxlengthREG.20.7

    -----------------------------------------------------------------------------------------

      --Begin Test case MaxlengthREG.20.8
      --Description: HMI responds OnInteriorVehicleData to RSDL with out upper bound for REG (257)
        function Test:OnInteriorVehicleData_OutUpperBoundREG()
              --hmi side: sending RC.OnInteriorVehicleData notification
              self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
                      moduleData =
                      {
                        radioControlData =
                        {
                          radioEnable = true,
                          frequencyInteger = 105,
                          frequencyFraction = 3,
                          band = "AM",
                          state = "ACQUIRED",
                          hdChannel = 1,
                          availableHDs = 1,
                          signalStrength = 50,
                          rdsData =
                          {
                            PS = "12345678",
                            RT = "",
                            CT = "123456789012345678901234",
                            PI = "",
                            PTY = 0,
                            TP = true,
                            TA = false,
                            REG = "This is mainly used in countries where national broadcasters run 'region-specific' programming such as regional opt-outs on some of their transmitters. This functionality allows the user to 'lock-down' the set to their current region or let the radio tunez"
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
                      }
              })

              --mobile side: Absence of notifications
              EXPECT_NOTIFICATION("OnInteriorVehicleData")
              :Times(0)

        end
      --End Test case MaxlengthREG.20.8


  --End Test case MaxlengthREG.20
--=================================================BEGIN TEST CASES 20==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end