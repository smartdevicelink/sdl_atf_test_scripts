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



--=================================================BEGIN TEST CASES 1==========================================================--

  --Begin Test case ResponseMissingCheck.1
  --Description:  --Invalid response expected by mobile app

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --<2.>In case a mobile app sends a valid request to RSDL, RSDL transfers this request to HMI, and HMI responds with one or more of mandatory per rc-HMI_API params missing to RSDL, RSDL must log an error and respond with "resultCode: GENERIC_ERROR, success: false, info: 'Invalid response from the vehicle'" to this mobile app's request (Exception: GetInteriorVehicleData, see Requirement).
        --<TODO>: Requirement Need to update script after for this question

      --Begin Test case ResponseMissingCheck.1.1
      --Description: Check processing response with interiorVehicleDataCapabilities missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingInteriorVehicleDataCapabilities()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })

        end
      --End Test case ResponseMissingCheck.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.2
      --Description: Check processing response with moduleZone missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingModuleZone()
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
                                          moduleType = "RADIO"
                                        }
                                    }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })
        end
      --End Test case ResponseMissingCheck.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.3
      --Description: Check processing response with col missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingCol()
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
                                            colspan = 2,
                                            level = 0,
                                            levelspan = 1,
                                            row = 0,
                                            rowspan=  2
                                          },
                                          moduleType = "RADIO"
                                        }
                                    }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })
        end
      --End Test case ResponseMissingCheck.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.4
      --Description: Check processing response with colspan missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingColspan()
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
                                            col = 0,
                                            level = 0,
                                            levelspan = 1,
                                            row = 0,
                                            rowspan=  2
                                          },
                                          moduleType = "RADIO"
                                        }
                                    }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })
        end
      --End Test case ResponseMissingCheck.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.5
      --Description: Check processing response with level missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingLevel()
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
                                            col = 0,
                                            colspan = 2,
                                            levelspan = 1,
                                            row = 0,
                                            rowspan=  2
                                          },
                                          moduleType = "RADIO"
                                        }
                                    }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })
        end
      --End Test case ResponseMissingCheck.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.6
      --Description: Check processing response with levelspan missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingLevelspan()
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
                                            col = 0,
                                            colspan = 2,
                                            level = 0,
                                            row = 0,
                                            rowspan=  2
                                          },
                                          moduleType = "RADIO"
                                        }
                                    }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })
        end
      --End Test case ResponseMissingCheck.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.7
      --Description: Check processing response with row missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingRow()
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
                                            col = 0,
                                            colspan = 2,
                                            level = 0,
                                            levelspan = 1,
                                            rowspan=  2
                                          },
                                          moduleType = "RADIO"
                                        }
                                    }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })
        end
      --End Test case ResponseMissingCheck.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.8
      --Description: Check processing response with rowspan missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingRowspan()
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
                                            col = 0,
                                            colspan = 2,
                                            level = 0,
                                            levelspan = 1,
                                            row = 0
                                          },
                                          moduleType = "RADIO"
                                        }
                                    }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })
        end
      --End Test case ResponseMissingCheck.1.8

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.9
      --Description: Check processing response with moduleType missing
        function Test:GetInteriorVehicleDataCapabilities_ResponseMissingModuleType()
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
                                            col = 0,
                                            colspan = 2,
                                            level = 0,
                                            levelspan = 1,
                                            row = 0,
                                            rowspan=  2
                                          }
                                        }
                                    }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
                                              {
                                                moduleZone = {
                                                  col = 0,
                                                  row = 0,
                                                  level = 0,
                                                  colspan = 2,
                                                  rowspan = 2,
                                                  levelspan = 1
                                                },
                                                moduleType = "RADIO"
                                              }
                                            }
        })
        end
      --End Test case ResponseMissingCheck.1.9

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.10
      --Description: Check processing response with moduleData missing
        function Test:SetInteriorVehicleData_ResponseMissingModuleData()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.10

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.11
      --Description: Check processing response with moduleType missing
        function Test:SetInteriorVehicleData_ResponseMissingModuleType()
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.11

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.12
      --Description: Check processing response with moduleZone missing
        function Test:SetInteriorVehicleData_ResponseMissingModuleZone()
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.12

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.13
      --Description: Check processing response with colspan missing
        function Test:SetInteriorVehicleData_ResponseMissingColspan()
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.14
      --Description: Check processing response with row missing
        function Test:SetInteriorVehicleData_ResponseMissingRow()
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
                                colspan = 2,
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.15
      --Description: Check processing response with rowspan missing
        function Test:SetInteriorVehicleData_ResponseMissingRowspan()
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
                                colspan = 2,
                                row = 0,
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.15

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.16
      --Description: Check processing response with col missing
        function Test:SetInteriorVehicleData_ResponseMissingCol()
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
                                colspan = 2,
                                row = 0,
                                rowspan = 2,
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.16

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.17
      --Description: Check processing response with levelspan missing
        function Test:SetInteriorVehicleData_ResponseMissingLevelspan()
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
                                colspan = 2,
                                row = 0,
                                rowspan = 2,
                                col = 0,
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.17

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.18
      --Description: Check processing response with level missing
        function Test:SetInteriorVehicleData_ResponseMissingLevel()
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
                                colspan = 2,
                                row = 0,
                                rowspan = 2,
                                col = 0,
                                levelspan = 1
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.18

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.20
      --Description: Check processing response with climateControlData missing
        function Test:SetInteriorVehicleData_ResponseMissingClimateControlData()
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
      --End Test case ResponseMissingCheck.1.20

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.21
      --Description: Check processing response with fanSpeed missing
        function Test:SetInteriorVehicleData_ResponseMissingFanSpeed()
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

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.21

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.22
      --Description: Check processing response with circulateAirEnable missing
        function Test:SetInteriorVehicleData_ResponseMissingCirculateAirEnable()
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

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.22

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.23
      --Description: Check processing response with dualModeEnable missing
        function Test:SetInteriorVehicleData_ResponseMissingDualModeEnable()
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

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.23

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.24
      --Description: Check processing response with currentTemp missing
        function Test:SetInteriorVehicleData_ResponseMissingCurrentTemp()
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
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.24

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.25
      --Description: Check processing response with defrostZone missing
        function Test:SetInteriorVehicleData_ResponseMissingDefrostZone()
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
                fandSpeed = 50,
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
                                acEnable = true,
                                desiredTemp = 24,
                                autoModeEnable = true,
                                temperatureUnit = "CELSIUS"
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.25

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.26
      --Description: Check processing response with acEnable missing
        function Test:SetInteriorVehicleData_ResponseMissingAcEnable()
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
                                desiredTemp = 24,
                                autoModeEnable = true,
                                temperatureUnit = "CELSIUS"
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.26

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.27
      --Description: Check processing response with desiredTemp missing
        function Test:SetInteriorVehicleData_ResponseMissingDesiredTemp()
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
                                autoModeEnable = true,
                                temperatureUnit = "CELSIUS"
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.27

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.28
      --Description: Check processing response with autoModeEnable missing
        function Test:SetInteriorVehicleData_ResponseMissingAutoModeEnable()
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
                                temperatureUnit = "CELSIUS"
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.28

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.29
      --Description: Check processing response with TemperatureUnit missing
        function Test:SetInteriorVehicleData_ResponseMissingTemperatureUnit()
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
                                autoModeEnable = true
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.29

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.30
      --Description: Check processing response with radioControlData missing
        function Test:SetInteriorVehicleData_ResponseMissingRadioControlData()
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
      --End Test case ResponseMissingCheck.1.30

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.31
      --Description: Check processing response with radioEnable missing
        function Test:SetInteriorVehicleData_ResponseMissingRadioEnable()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.31

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.32
      --Description: Check processing response with frequencyInteger missing
        function Test:SetInteriorVehicleData_ResponseMissingFrequencyInteger()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.32

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.33
      --Description: Check processing response with frequencyFraction missing
        function Test:SetInteriorVehicleData_ResponseMissingFrequencyFraction()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.33

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.34
      --Description: Check processing response with band missing
        function Test:SetInteriorVehicleData_ResponseMissingBand()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.34

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.35
      --Description: Check processing response with hdChannel missing
        function Test:SetInteriorVehicleData_ResponseMissingHdChannel()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.35

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.36
      --Description: Check processing response with state missing
        function Test:SetInteriorVehicleData_ResponseMissingState()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.36

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.37
      --Description: Check processing response with availableHDs missing
        function Test:SetInteriorVehicleData_ResponseMissingAvailableHDs()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.37

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.38
      --Description: Check processing response with signalStrength missing
        function Test:SetInteriorVehicleData_ResponseMissingSignalStrength()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.38

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.39
      --Description: Check processing response with rdsData missing
        function Test:SetInteriorVehicleData_ResponseMissingRdsData()
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
      --End Test case ResponseMissingCheck.1.39

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.40
      --Description: Check processing response with PS missing
        function Test:SetInteriorVehicleData_ResponseMissingPS()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.40

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.41
      --Description: Check processing response with RT missing
        function Test:SetInteriorVehicleData_ResponseMissingRT()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.41

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.42
      --Description: Check processing response with CT missing
        function Test:SetInteriorVehicleData_ResponseMissingCT()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.42

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.43
      --Description: Check processing response with PI missing
        function Test:SetInteriorVehicleData_ResponseMissingPI()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.43

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.44
      --Description: Check processing response with PTY missing
        function Test:SetInteriorVehicleData_ResponseMissingPTY()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.44

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.45
      --Description: Check processing response with TP missing
        function Test:SetInteriorVehicleData_ResponseMissingTP()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.45

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.46
      --Description: Check processing response with TA missing
        function Test:SetInteriorVehicleData_ResponseMissingTA()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.46

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.47
      --Description: Check processing response with REG missing
        function Test:SetInteriorVehicleData_ResponseMissingREG()
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
                                  TA = false
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
      --End Test case ResponseMissingCheck.1.47

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.48
      --Description: Check processing response with signalChangeThreshold missing
        function Test:SetInteriorVehicleData_ResponseMissingSignalChangeThreshold()
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
                                  REG = ""
                                }
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
      --End Test case ResponseMissingCheck.1.48

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.49
      --Description: Check processing response with moduleType missing
        function Test:SetInteriorVehicleData_ResponseMissingModuleType()
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
                                  REG = ""
                                },
                                signalChangeThreshold = 10
                              },
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
      --End Test case ResponseMissingCheck.1.49

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.51
      --Description: Check processing response with moduleData missing
        function Test:GetInteriorVehicleData_ResponseMissingModuleData()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.51

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.52
      --Description: Check processing response with moduleType missing
        function Test:GetInteriorVehicleData_ResponseMissingModuleType()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    moduleData =
                                    {
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.52

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.53
      --Description: Check processing response with moduleZone missing
        function Test:GetInteriorVehicleData_ResponseMissingModuleZone()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                            moduleData =
                            {
                              moduleType = "CLIMATE",
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.53

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.54
      --Description: Check processing response with colspan missing
        function Test:GetInteriorVehicleData_ResponseMissingColspan()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                            moduleData =
                            {
                              moduleType = "CLIMATE",
                              moduleZone =
                              {
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.54

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.55
      --Description: Check processing response with row missing
        function Test:GetInteriorVehicleData_ResponseMissingRow()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                            moduleData =
                            {
                              moduleType = "CLIMATE",
                              moduleZone =
                              {
                                colspan = 2,
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.55

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.56
      --Description: Check processing response with rowspan missing
        function Test:GetInteriorVehicleData_ResponseMissingRowspan()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                            moduleData =
                            {
                              moduleType = "CLIMATE",
                              moduleZone =
                              {
                                colspan = 2,
                                row = 0,
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.56

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.57
      --Description: Check processing response with col missing
        function Test:GetInteriorVehicleData_ResponseMissingCol()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                            moduleData =
                            {
                              moduleType = "CLIMATE",
                              moduleZone =
                              {
                                colspan = 2,
                                row = 0,
                                rowspan = 2,
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.57

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.58
      --Description: Check processing response with levelspan missing
        function Test:GetInteriorVehicleData_ResponseMissingLevelspan()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                            moduleData =
                            {
                              moduleType = "CLIMATE",
                              moduleZone =
                              {
                                colspan = 2,
                                row = 0,
                                rowspan = 2,
                                col = 0,
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.58

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.59
      --Description: Check processing response with level missing
        function Test:GetInteriorVehicleData_ResponseMissingLevel()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                            moduleData =
                            {
                              moduleType = "CLIMATE",
                              moduleZone =
                              {
                                colspan = 2,
                                row = 0,
                                rowspan = 2,
                                col = 0,
                                levelspan = 1
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
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.59

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.60
      --Description: Check processing response with climateControlData missing
        function Test:GetInteriorVehicleData_ResponseMissingClimateControlData()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
                              }
                            }
            })
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})

        end
      --End Test case ResponseMissingCheck.1.60

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.61
      --Description: Check processing response with fanSpeed missing
        function Test:GetInteriorVehicleData_ResponseMissingFanSpeed()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.61

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.62
      --Description: Check processing response with circulateAirEnable missing
        function Test:GetInteriorVehicleData_ResponseMissingCirculateAirEnable()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.62

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.63
      --Description: Check processing response with dualModeEnable missing
        function Test:GetInteriorVehicleData_ResponseMissingDualModeEnable()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.63

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.64
      --Description: Check processing response with currentTemp missing
        function Test:GetInteriorVehicleData_ResponseMissingCurrentTemp()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.64

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.65
      --Description: Check processing response with defrostZone missing
        function Test:GetInteriorVehicleData_ResponseMissingDefrostZone()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
                                acEnable = true,
                                desiredTemp = 24,
                                autoModeEnable = true,
                                temperatureUnit = "CELSIUS"
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.65

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.66
      --Description: Check processing response with acEnable missing
        function Test:GetInteriorVehicleData_ResponseMissingAcEnable()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
                                desiredTemp = 24,
                                autoModeEnable = true,
                                temperatureUnit = "CELSIUS"
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.66

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.67
      --Description: Check processing response with desiredTemp missing
        function Test:GetInteriorVehicleData_ResponseMissingDesiredTemp()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
                                autoModeEnable = true,
                                temperatureUnit = "CELSIUS"
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.67

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.68
      --Description: Check processing response with autoModeEnable missing
        function Test:GetInteriorVehicleData_ResponseMissingAutoModeEnable()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
                                temperatureUnit = "CELSIUS"
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.68

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.69
      --Description: Check processing response with TemperatureUnit missing
        function Test:GetInteriorVehicleData_ResponseMissingTemperatureUnit()
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
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
                                autoModeEnable = true
                              }
                            }
            })
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.69

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.70
      --Description: Check processing response with radioControlData missing
        function Test:GetInteriorVehicleData_ResponseMissingRadioControlData()
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
      --End Test case ResponseMissingCheck.1.70

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.71
      --Description: Check processing response with radioEnable missing
        function Test:GetInteriorVehicleData_ResponseMissingRadioEnable()
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.71

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.72
      --Description: Check processing response with frequencyInteger missing
        function Test:GetInteriorVehicleData_ResponseMissingFrequencyInteger()
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
                                radioEnable = true,
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.72

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.73
      --Description: Check processing response with frequencyFraction missing
        function Test:GetInteriorVehicleData_ResponseMissingFrequencyFraction()
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
                                radioEnable = true,
                                frequencyInteger = 105,
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.73

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.74
      --Description: Check processing response with band missing
        function Test:GetInteriorVehicleData_ResponseMissingBand()
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
                                radioEnable = true,
                                frequencyInteger = 105,
                                frequencyFraction = 3,
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.74

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.75
      --Description: Check processing response with hdChannel missing
        function Test:GetInteriorVehicleData_ResponseMissingHdChannel()
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
                                radioEnable = true,
                                frequencyInteger = 105,
                                frequencyFraction = 3,
                                band = "AM",
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.75

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.76
      --Description: Check processing response with state missing
        function Test:GetInteriorVehicleData_ResponseMissingState()
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
                                radioEnable = true,
                                frequencyInteger = 105,
                                frequencyFraction = 3,
                                band = "AM",
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.76

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.77
      --Description: Check processing response with availableHDs missing
        function Test:GetInteriorVehicleData_ResponseMissingAvailableHDs()
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
                                radioEnable = true,
                                frequencyInteger = 105,
                                frequencyFraction = 3,
                                band = "AM",
                                hdChannel = 1,
                                state = "ACQUIRED",
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.77

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.78
      --Description: Check processing response with signalStrength missing
        function Test:GetInteriorVehicleData_ResponseMissingSignalStrength()
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
                                radioEnable = true,
                                frequencyInteger = 105,
                                frequencyFraction = 3,
                                band = "AM",
                                hdChannel = 1,
                                state = "ACQUIRED",
                                availableHDs = 1,
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
          end)

        --mobile side: expect SUCCESS response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
        end
      --End Test case ResponseMissingCheck.1.78

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.79
      --Description: Check processing response with rdsData missing
        function Test:GetInteriorVehicleData_ResponseMissingRdsData()
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
                                radioEnable = true,
                                frequencyInteger = 105,
                                frequencyFraction = 3,
                                band = "AM",
                                hdChannel = 1,
                                state = "ACQUIRED",
                                availableHDs = 1,
                                signalStrength = 50,
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
      --End Test case ResponseMissingCheck.1.79

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.80
      --Description: Check processing response with PS missing
        function Test:GetInteriorVehicleData_ResponseMissingPS()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.80

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.81
      --Description: Check processing response with RT missing
        function Test:GetInteriorVehicleData_ResponseMissingRT()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.81

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.82
      --Description: Check processing response with CT missing
        function Test:GetInteriorVehicleData_ResponseMissingCT()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.82

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.83
      --Description: Check processing response with PI missing
        function Test:GetInteriorVehicleData_ResponseMissingPI()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.83

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.84
      --Description: Check processing response with PTY missing
        function Test:GetInteriorVehicleData_ResponseMissingPTY()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.84

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.85
      --Description: Check processing response with TP missing
        function Test:GetInteriorVehicleData_ResponseMissingTP()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.85

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.86
      --Description: Check processing response with TA missing
        function Test:GetInteriorVehicleData_ResponseMissingTA()
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
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseMissingCheck.1.86

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.87
      --Description: Check processing response with REG missing
        function Test:GetInteriorVehicleData_ResponseMissingREG()
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
                                  TA = false
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
      --End Test case ResponseMissingCheck.1.87

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.88
      --Description: Check processing response with signalChangeThreshold missing
        function Test:GetInteriorVehicleData_ResponseMissingSignalChangeThreshold()
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
                                }
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
      --End Test case ResponseMissingCheck.1.88

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseMissingCheck.1.89
      --Description: Check processing response with moduleType missing
        function Test:GetInteriorVehicleData_ResponseMissingModuleType()
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
      --End Test case ResponseMissingCheck.1.89

  --End Test case ResponseMissingCheck.1
--=================================================END TEST CASES 1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
