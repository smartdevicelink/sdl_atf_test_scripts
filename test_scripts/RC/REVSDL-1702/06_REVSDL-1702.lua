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

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: SetInteriorVehicleData: conditions to return----------------------
----------------------------------READ_ONLY resultCode---------------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 6==========================================================--
  --Begin Test suit CommonRequestCheck.6 for Req.#6

  --Description: In case: application sends valid SetInteriorVehicleData with just read-only parameters in "radioControlData" struct, for muduleType: CLIMATE, RSDL must
            --HMI responds with "resultCode: READ_ONLY" RSDL must send "resultCode: READ_ONLY, success:false" to the related mobile application.


  --Begin Test case CommonRequestCheck.6.1
  --Description:  --PASSENGER's Device
          --RSDL responds with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.

    --Requirement/Diagrams id in jira:
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/127928/127928_model_SetInteriorVehicleData-READ_ONLY.png

    --Verification criteria:
        --For PASSENGER'S Device

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.1
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and all parameter
        function Test:PASSENGER_READONLY_AllParams()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                defrostZone = "FRONT",
                acEnable = true,
                desiredTemp = 24,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.2
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and fanSpeed parameter
        function Test:PASSENGER_READONLY_fanSpeed()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                fanSpeed = 50
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.3
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and circulateAirEnable parameter
        function Test:PASSENGER_READONLY_circulateAirEnable()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                circulateAirEnable = true,
                currentTemp = 30
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                circulateAirEnable = true
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.4
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and dualModeEnable parameter
        function Test:PASSENGER_READONLY_dualModeEnable()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                dualModeEnable = true,
                currentTemp = 30
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                dualModeEnable = true
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.5
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and defrostZone parameter
        function Test:PASSENGER_READONLY_defrostZone()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                defrostZone = "FRONT"
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                defrostZone = "FRONT"
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.6
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and acEnable parameter
        function Test:PASSENGER_READONLY_acEnable()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                acEnable = true
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                acEnable = true
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.7
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and desiredTemp parameter
        function Test:PASSENGER_READONLY_desiredTemp()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                desiredTemp = 24
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                desiredTemp = 24
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.8
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and autoModeEnable parameter
        function Test:PASSENGER_READONLY_autoModeEnable()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                autoModeEnable = true
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                autoModeEnable = true
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.1.9
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and temperatureUnit parameter
        function Test:PASSENGER_READONLY_temperatureUnit()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                temperatureUnit = "CELSIUS"
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                temperatureUnit = "CELSIUS"
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.1.9

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.6.1


  --Begin Test case CommonRequestCheck.6.2
  --Description:  --DRIVER's Device
          --RSDL responds with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.

    --Requirement/Diagrams id in jira:
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/127928/127928_model_SetInteriorVehicleData-READ_ONLY.png

    --Verification criteria:
        --For DRIVER'S Device

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.0
      --Description: Sending SetInteriorVehicleData request with just read-only parameters
        function Test:SetPASSENGERToDRIVER()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          self.mobileSession:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.6.2.0

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.1
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and all parameter
        function Test:DRIVER_READONLY_AllParams()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                defrostZone = "FRONT",
                acEnable = true,
                desiredTemp = 24,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.2
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and fanSpeed parameter
        function Test:DRIVER_READONLY_fanSpeed()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                fanSpeed = 50
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.3
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and circulateAirEnable parameter
        function Test:DRIVER_READONLY_circulateAirEnable()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                circulateAirEnable = true,
                currentTemp = 30
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                circulateAirEnable = true
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.4
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and dualModeEnable parameter
        function Test:DRIVER_READONLY_dualModeEnable()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                dualModeEnable = true,
                currentTemp = 30
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                dualModeEnable = true
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.5
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and defrostZone parameter
        function Test:DRIVER_READONLY_defrostZone()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                defrostZone = "FRONT"
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                defrostZone = "FRONT"
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.6
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and acEnable parameter
        function Test:DRIVER_READONLY_acEnable()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                acEnable = true
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                acEnable = true
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.7
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and desiredTemp parameter
        function Test:DRIVER_READONLY_desiredTemp()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                desiredTemp = 24
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                desiredTemp = 24
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.8
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and autoModeEnable parameter
        function Test:DRIVER_READONLY_autoModeEnable()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                autoModeEnable = true
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                autoModeEnable = true
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.8

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.6.2.9
      --Description: Sending SetInteriorVehicleData request with and read-only parameters and temperatureUnit parameter
        function Test:DRIVER_READONLY_temperatureUnit()
          --mobile side: sending SetInteriorVehicleData request with just read-only parameters and settable params in "radioControlData" struct, for muduleType: RADIO
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
                currentTemp = 30,
                temperatureUnit = "CELSIUS"
              }
            }
          })

        --hmi side: expect RC.SetInteriorVehicleData request
        EXPECT_HMICALL("RC.SetInteriorVehicleData",
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
                temperatureUnit = "CELSIUS"
              }
            }
          }
        )
        :ValidIf (function(_,data)
          --RSDL must cut the read-only parameters off and process this RPC as assigned
          if data.params.moduleData.climateControlData.currentTemp then
            print(" --SDL sends fake parameter to HMI ")
            for key,value in pairs(data.params.moduleData.climateControlData) do print(key,value) end
            return false
          else
            return true
          end
        end)
        :Do(function(_,data)
          --hmi side: sending RC.SetInteriorVehicleData response
          ResponseId = data.id
          local function ValidationResponse()
            self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":26,"message":"One of the provided IDs is not valid","data":{"method":"RC.SetInteriorVehicleData"}}}')
          end
          RUN_AFTER(ValidationResponse, 3000)
        end)

        --mobile side: expect READ_ONLY response
        EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

        end
      --End Test case CommonRequestCheck.6.2.9

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.6.2

--=================================================END TEST CASES 6==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end