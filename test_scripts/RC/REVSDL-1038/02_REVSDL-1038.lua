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
-------------------------------------STARTING COMMON FUNCTIONS-------------------------------
---------------------------------------------------------------------------------------------


--Creating an interiorVehicleDataCapability with specificed zone and moduleType
local function interiorVehicleDataCapability(strModuleType, icol, icolspan, ilevel, ilevelspan, irow, irowspan)
  return{
      moduleZone = {
        col = icol,
        colspan = icolspan,
        level = ilevel,
        levelspan = ilevelspan,
        row = irow,
        rowspan=  irowspan
      },
      moduleType = strModuleType
  }
end

--Creating an interiorVehicleDataCapabilities array with maxsize = iMaxsize
local function interiorVehicleDataCapabilities(strModuleType, icol, icolspan, ilevel, ilevelspan, irow, irowspan, iMaxsize)
  local items = {}
  for _=1, iMaxsize do
    table.insert(items, interiorVehicleDataCapability(strModuleType, icol, icolspan, ilevel, ilevelspan, irow, irowspan))
  end
  return items
end

---------------------------------------------------------------------------------------------
----------------------------------------END COMMON FUNCTIONS---------------------------------
---------------------------------------------------------------------------------------------

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

--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test case ResponseOutOfBoundCheck.2
  --Description:  --Invalid response expected by mobile app

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --<3.>In case a mobile app sends a valid request to RSDL, RSDL transfers this request to HMI, and HMI responds with one or more of out-of-bounds per rc-HMI_API values to RSDL, RSDL must log an error and respond with "resultCode: GENERIC_ERROR, success: false, info: 'Invalid response from the vehicle'" to this mobile app's request (Exception: GetInteriorVehicleDataCapabilities, see Requirement).

      --Begin Test case ResponseOutOfBoundCheck.2.1
      --Description: Check processing response with interiorVehicleDataCapabilities out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutLowerBoundInteriorVehicleDataCapabilities()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                    interiorVehicleDataCapabilities = {}

              }
            )
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
      --End Test case ResponseOutOfBoundCheck.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.2
      --Description: Check processing response with col out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutLowerBoundCol()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = -1,
                                        colspan = 2,
                                        level = 0,
                                        levelspan = 1,
                                        row = 0,
                                        rowspan=  2
                                      },
                                      moduleType = "RADIO"
                                    }
                                }

              }
            )
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
      --End Test case ResponseOutOfBoundCheck.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.3
      --Description: Check processing response with colspan out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutLowerBoundColspan()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = -1,
                                        level = 0,
                                        levelspan = 1,
                                        row = 0,
                                        rowspan=  2
                                      },
                                      moduleType = "RADIO"
                                    }
                                }

              }
            )
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
      --End Test case ResponseOutOfBoundCheck.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.4
      --Description: Check processing response with level out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutLowerBoundLevel()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 2,
                                        level = -1,
                                        levelspan = 1,
                                        row = 0,
                                        rowspan=  2
                                      },
                                      moduleType = "RADIO"
                                    }
                                }

              }
            )
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
      --End Test case ResponseOutOfBoundCheck.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.5
      --Description: Check processing response with levelspan out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutLowerBoundLevelspan()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 2,
                                        level = 0,
                                        levelspan = -1,
                                        row = 0,
                                        rowspan=  2
                                      },
                                      moduleType = "RADIO"
                                    }
                                }

              }
            )
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
      --End Test case ResponseOutOfBoundCheck.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.6
      --Description: Check processing response with row out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutLowerBoundRow()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 2,
                                        level = 0,
                                        levelspan = 1,
                                        row = -1,
                                        rowspan =  2
                                      },
                                      moduleType = "RADIO"
                                    }
                                }

              }
            )
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
      --End Test case ResponseOutOfBoundCheck.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.7
      --Description: Check processing response with rowspan out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutLowerBoundRowspan()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 2,
                                        level = 0,
                                        levelspan = 1,
                                        row = 0,
                                        rowspan=  -1
                                      },
                                      moduleType = "RADIO"
                                    }
                                }

              }
            )
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
      --End Test case ResponseOutOfBoundCheck.2.7

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.8
      --Description: Check processing response with interiorVehicleDataCapabilities out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutUpperBoundInteriorVehicleDataCapabilities()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with interiorVehicleDataCapabilities size = 1001
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                    interiorVehicleDataCapabilities = interiorVehicleDataCapabilities("RADIO", 2, 0, 2, 0, 1, 0, 1001)

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
      --End Test case ResponseOutOfBoundCheck.2.8

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.9
      --Description: Check processing response with col out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutUpperBoundCol()
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
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with col out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 101,
                                        colspan = 2,
                                        level = 0,
                                        levelspan = 1,
                                        row = 0,
                                        rowspan=  2
                                      },
                                      moduleType = "RADIO"
                                    }
                                }

              }
            )
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
      --End Test case ResponseOutOfBoundCheck.2.9

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.10
      --Description: Check processing response with colspan out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutUpperBoundColspan()
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
            moduleTypes = {"CLIMATE"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 101,
                                        level = 0,
                                        levelspan = 1,
                                        row = 0,
                                        rowspan=  2
                                      },
                                      moduleType = "CLIMATE"
                                    }
                                }

              }
            )
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
                                                  moduleType = "CLIMATE"
                                                }
                                            }
        })
        end
      --End Test case ResponseOutOfBoundCheck.2.10

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.11
      --Description: Check processing response with level out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutUpperBoundLevel()
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
            moduleTypes = {"CLIMATE"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 2,
                                        level = 101,
                                        levelspan = 1,
                                        row = 0,
                                        rowspan=  2
                                      },
                                      moduleType = "CLIMATE"
                                    }
                                }

              }
            )
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
                                                  moduleType = "CLIMATE"
                                                }
                                            }
        })
        end
      --End Test case ResponseOutOfBoundCheck.2.11

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.12
      --Description: Check processing response with levelspan out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutUpperBoundLevelspan()
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
            moduleTypes = {"CLIMATE"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 2,
                                        level = 0,
                                        levelspan = 101,
                                        row = 0,
                                        rowspan=  2
                                      },
                                      moduleType = "CLIMATE"
                                    }
                                }

              }
            )
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
                                                  moduleType = "CLIMATE"
                                                }
                                            }
        })
        end
      --End Test case ResponseOutOfBoundCheck.2.12

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.13
      --Description: Check processing response with row out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutUpperBoundRow()
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
            moduleTypes = {"CLIMATE"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 2,
                                        level = 0,
                                        levelspan = 1,
                                        row = 101,
                                        rowspan =  2
                                      },
                                      moduleType = "CLIMATE"
                                    }
                                }

              }
            )
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
                                                  moduleType = "CLIMATE"
                                                }
                                            }
        })
        end
      --End Test case ResponseOutOfBoundCheck.2.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.14
      --Description: Check processing response with rowspan out of bound
        function Test:GetInteriorVehicleDataCapabilities_ResponseOutUpperBoundRowspan()
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
            moduleTypes = {"CLIMATE"}
          })

        --hmi side: expect RC.GetInteriorVehicleDataCapabilities request
        EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
          :Do(function(_,data)
            --hmi side: sending RC.GetInteriorVehicleDataCapabilities response with out of bound
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
                                    interiorVehicleDataCapabilities = {
                                    {
                                      moduleZone = {
                                        col = 0,
                                        colspan = 2,
                                        level = 0,
                                        levelspan = 1,
                                        row = 0,
                                        rowspan=  101
                                      },
                                      moduleType = "CLIMATE"
                                    }
                                }

              }
            )
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
                                                  moduleType = "CLIMATE"
                                                }
                                            }
        })
        end
      --End Test case ResponseOutOfBoundCheck.2.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.1
      --Description: SetInteriorVehicleData with all parameters out of bounds
        function Test:SetInteriorVehicleData_ResponseAllParamsOutLowerBound()
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
                colspan = -1,
                row = -1,
                rowspan = -1,
                col = -1,
                levelspan = -1,
                level = -1
              },
              climateControlData =
              {
                fanSpeed = -1,
                circulateAirEnable = true,
                dualModeEnable = true,
                currentTemp = -1,
                defrostZone = "FRONT",
                acEnable = true,
                desiredTemp = -1,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
            })
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})

        end
      --End Test case ResponseOutOfBoundCheck.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.2
      --Description: SetInteriorVehicleData with Colspan parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseColspanOutLowerBound()
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
                colspan = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.3
      --Description: SetInteriorVehicleData with row parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseRowOutLowerBound()
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
                row = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.4
      --Description: SetInteriorVehicleData with rowspan parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseRowspanOutLowerBound()
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
                rowspan = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.5
      --Description: SetInteriorVehicleData with col parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseColOutLowerBound()
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
                col = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.6
      --Description: SetInteriorVehicleData with levelspan parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseLevelspanOutLowerBound()
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
                levelspan = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.7
      --Description: SetInteriorVehicleData with level parameter out of bounds
        function Test:SetInteriorVehicleData_ResponselevelOutLowerBound()
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
                level = -1
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
      --End Test case ResponseOutOfBoundCheck.2.7

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.8
      --Description: SetInteriorVehicleData with frequencyInteger parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseFrequencyIntegerOutLowerBound()
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
                frequencyInteger = -1,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.8

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.9
      --Description: SetInteriorVehicleData with frequencyFraction parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseFrequencyFractionOutLowerBound()
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
                frequencyFraction = -1,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.9

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.10
      --Description: SetInteriorVehicleData with hdChannel parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseHdChannelOutLowerBound()
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
                hdChannel = 0,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.10

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.11
      --Description: SetInteriorVehicleData with availableHDs parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseAvailableHDsOutLowerBound()
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
                availableHDs = 0,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.11

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.12
      --Description: SetInteriorVehicleData with signalStrength parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseSignalStrengthOutLowerBound()
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
                signalStrength = -1,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.12

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.13
      --Description: SetInteriorVehicleData with signalChangeThreshold parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseSignalChangeThresholdOutLowerBound()
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdent",
                  PTY = 0,
                  TP = true,
                  TA = false,
                  REG = "don't mention min,max length"
                },
                signalChangeThreshold = -1
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
      --End Test case ResponseOutOfBoundCheck.2.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.14
      --Description: SetInteriorVehicleData with fanSpeed parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseFanSpeedOutLowerBound()
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
                fanSpeed = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.15
      --Description: SetInteriorVehicleData with currentTemp parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseCurrentTempOutLowerBound()
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
                currentTemp = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.15

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.16
      --Description: SetInteriorVehicleData with desiredTemp parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseDesiredTempOutLowerBound()
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
                desiredTemp = -1,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.16

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.17
      --Description: SetInteriorVehicleData with all parameters out of bounds
        function Test:SetInteriorVehicleData_ResponseAllParamsOutUpperBound()
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
                colspan = 101,
                row = 101,
                rowspan = 101,
                col = 101,
                levelspan = 101,
                level = 101
              },
              climateControlData =
              {
                fanSpeed = 101,
                circulateAirEnable = true,
                dualModeEnable = true,
                currentTemp = 101,
                defrostZone = "FRONT",
                acEnable = true,
                desiredTemp = 101,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.17

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.18
      --Description: SetInteriorVehicleData with Colspan parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseColspanOutUpperBound()
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
                colspan = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.18

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.19
      --Description: SetInteriorVehicleData with row parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseRowOutUpperBound()
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
                row = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.19

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.20
      --Description: SetInteriorVehicleData with rowspan parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseRowspanOutUpperBound()
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
                rowspan = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.20

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.21
      --Description: SetInteriorVehicleData with col parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseColOutUpperBound()
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
                col = 101,
                levelspan = 1,
                level = 0
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.21

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.22
      --Description: SetInteriorVehicleData with levelspan parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseLevelspanOutUpperBound()
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
                levelspan = 101,
                level = 0
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.22

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.23
      --Description: SetInteriorVehicleData with level parameter out of bounds
        function Test:SetInteriorVehicleData_ResponselevelOutUpperBound()
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
                level = 101
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.23

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.24
      --Description: SetInteriorVehicleData with frequencyInteger parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseFrequencyIntegerOutUpperBound()
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
                frequencyInteger = 1711,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.24

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.25
      --Description: SetInteriorVehicleData with frequencyFraction parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseFrequencyFractionOutUpperBound()
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
                frequencyFraction = 10,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.25

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.26
      --Description: SetInteriorVehicleData with hdChannel parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseHdChannelOutUpperBound()
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
                hdChannel = 4,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.26

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.27
      --Description: SetInteriorVehicleData with availableHDs parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseAvailableHDsOutUpperBound()
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
                availableHDs = 4,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.27

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.28
      --Description: SetInteriorVehicleData with signalStrength parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseSignalStrengthOutUpperBound()
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
                signalStrength = 101,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.28

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.29
      --Description: SetInteriorVehicleData with signalChangeThreshold parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseSignalChangeThresholdOutUpperBound()
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdent",
                  PTY = 0,
                  TP = true,
                  TA = false,
                  REG = "don't mention min,max length"
                },
                signalChangeThreshold = 101
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
      --End Test case ResponseOutOfBoundCheck.2.29

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.30
      --Description: SetInteriorVehicleData with fanSpeed parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseFanSpeedOutUpperBound()
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
                fanSpeed = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.30

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.31
      --Description: SetInteriorVehicleData with currentTemp parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseCurrentTempOutUpperBound()
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
                currentTemp = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.31

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.32
      --Description: SetInteriorVehicleData with desiredTemp parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseDesiredTempOutUpperBound()
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
                desiredTemp = 101,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.32

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.33
      --Description: SetInteriorVehicleData with CT parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseCTOutLowerBound()
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-070",
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.33

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.34
      --Description: SetInteriorVehicleData with PTY parameter out of bounds
        function Test:SetInteriorVehicleData_ResponsePTYOutLowerBound()
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdent",
                  PTY = -1,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.34

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.35
      --Description: SetInteriorVehicleData with PS parameter out of bounds
        function Test:SetInteriorVehicleData_ResponsePSOutUpperBound()
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
                  PS = "123456789",
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.35

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.36
      --Description: SetInteriorVehicleData with PI parameter out of bounds
        function Test:SetInteriorVehicleData_ResponsePIOutUpperBound()
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdentI",
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.36

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.37
      --Description: SetInteriorVehicleData with RT parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseRTOutUpperBound()
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
                        RT = "RADIO TEXT Minlength = 0, Maxlength = 64 RADIO TEXT Minlength = 6",
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
                  }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.37

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.38
      --Description: SetInteriorVehicleData with CT parameter out of bounds
        function Test:SetInteriorVehicleData_ResponseCTOutUpperBound()
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
                        RT = "Radio text minlength = 0, maxlength = 64",
                        CT = "2015-09-29T18:46:19-07009",
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
                  }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.38


    -----------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------


      --Begin Test case ResponseOutOfBoundCheck.2.1
      --Description: GetInteriorVehicleData with all parameters out of bounds
        function Test:GetInteriorVehicleData_ResponseAllParamsOutLowerBound()
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
                level = 0
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
                colspan = -1,
                row = -1,
                rowspan = -1,
                col = -1,
                levelspan = -1,
                level = -1
              },
              climateControlData =
              {
                fanSpeed = -1,
                circulateAirEnable = true,
                dualModeEnable = true,
                currentTemp = -1,
                defrostZone = "FRONT",
                acEnable = true,
                desiredTemp = -1,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
            })
          end)

        --mobile side: expect GENERIC_ERROR response with info
        EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})

        end
      --End Test case ResponseOutOfBoundCheck.2.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.2
      --Description: GetInteriorVehicleData with Colspan parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseColspanOutLowerBound()
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
                level = 0
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
                colspan = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.3
      --Description: GetInteriorVehicleData with row parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseRowOutLowerBound()
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
                level = 0
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
                row = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.3

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.4
      --Description: GetInteriorVehicleData with rowspan parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseRowspanOutLowerBound()
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
                level = 0
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
                rowspan = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.4

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.5
      --Description: GetInteriorVehicleData with col parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseColOutLowerBound()
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
                level = 0
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
                col = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.5

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.6
      --Description: GetInteriorVehicleData with levelspan parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseLevelspanOutLowerBound()
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
                level = 0
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
                levelspan = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.6

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.7
      --Description: GetInteriorVehicleData with level parameter out of bounds
        function Test:GetInteriorVehicleData_ResponselevelOutLowerBound()
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
                level = 0
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
                level = -1
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
      --End Test case ResponseOutOfBoundCheck.2.7

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.8
      --Description: GetInteriorVehicleData with frequencyInteger parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseFrequencyIntegerOutLowerBound()
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
                level = 0
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
                frequencyInteger = -1,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.8

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.9
      --Description: GetInteriorVehicleData with frequencyFraction parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseFrequencyFractionOutLowerBound()
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
                level = 0
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
                frequencyFraction = -1,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.9

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.10
      --Description: GetInteriorVehicleData with hdChannel parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseHdChannelOutLowerBound()
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
                level = 0
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
                hdChannel = 0,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.10

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.11
      --Description: GetInteriorVehicleData with availableHDs parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseAvailableHDsOutLowerBound()
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
                level = 0
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
                availableHDs = 0,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.11

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.12
      --Description: GetInteriorVehicleData with signalStrength parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseSignalStrengthOutLowerBound()
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
                level = 0
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
                signalStrength = -1,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.12

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.13
      --Description: GetInteriorVehicleData with signalChangeThreshold parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseSignalChangeThresholdOutLowerBound()
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
                level = 0
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdent",
                  PTY = 0,
                  TP = true,
                  TA = false,
                  REG = "don't mention min,max length"
                },
                signalChangeThreshold = -1
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
      --End Test case ResponseOutOfBoundCheck.2.13

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.14
      --Description: GetInteriorVehicleData with fanSpeed parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseFanSpeedOutLowerBound()
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
                level = 0
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
                fanSpeed = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.14

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.15
      --Description: GetInteriorVehicleData with currentTemp parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseCurrentTempOutLowerBound()
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
                level = 0
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
                currentTemp = -1,
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
      --End Test case ResponseOutOfBoundCheck.2.15

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.16
      --Description: GetInteriorVehicleData with desiredTemp parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseDesiredTempOutLowerBound()
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
                level = 0
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
                desiredTemp = -1,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.16

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.17
      --Description: GetInteriorVehicleData with all parameters out of bounds
        function Test:GetInteriorVehicleData_ResponseAllParamsOutUpperBound()
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
                level = 0
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
                colspan = 101,
                row = 101,
                rowspan = 101,
                col = 101,
                levelspan = 101,
                level = 101
              },
              climateControlData =
              {
                fanSpeed = 101,
                circulateAirEnable = true,
                dualModeEnable = true,
                currentTemp = 101,
                defrostZone = "FRONT",
                acEnable = true,
                desiredTemp = 101,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.17

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.18
      --Description: GetInteriorVehicleData with Colspan parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseColspanOutUpperBound()
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
                level = 0
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
                colspan = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.18

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.19
      --Description: GetInteriorVehicleData with row parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseRowOutUpperBound()
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
                level = 0
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
                row = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.19

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.20
      --Description: GetInteriorVehicleData with rowspan parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseRowspanOutUpperBound()
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
                level = 0
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
                rowspan = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.20

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.21
      --Description: GetInteriorVehicleData with col parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseColOutUpperBound()
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
                level = 0
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
                col = 101,
                levelspan = 1,
                level = 0
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.21

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.22
      --Description: GetInteriorVehicleData with levelspan parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseLevelspanOutUpperBound()
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
                level = 0
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
                levelspan = 101,
                level = 0
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.22

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.23
      --Description: GetInteriorVehicleData with level parameter out of bounds
        function Test:GetInteriorVehicleData_ResponselevelOutUpperBound()
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
                level = 0
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
                level = 101
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.23

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.24
      --Description: GetInteriorVehicleData with frequencyInteger parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseFrequencyIntegerOutUpperBound()
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
                level = 0
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
                frequencyInteger = 1711,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.24

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.25
      --Description: GetInteriorVehicleData with frequencyFraction parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseFrequencyFractionOutUpperBound()
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
                level = 0
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
                frequencyFraction = 10,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.25

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.26
      --Description: GetInteriorVehicleData with hdChannel parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseHdChannelOutUpperBound()
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
                level = 0
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
                hdChannel = 4,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.26

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.27
      --Description: GetInteriorVehicleData with availableHDs parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseAvailableHDsOutUpperBound()
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
                level = 0
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
                availableHDs = 4,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.27

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.28
      --Description: GetInteriorVehicleData with signalStrength parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseSignalStrengthOutUpperBound()
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
                level = 0
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
                signalStrength = 101,
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
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.28

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.29
      --Description: GetInteriorVehicleData with signalChangeThreshold parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseSignalChangeThresholdOutUpperBound()
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
                level = 0
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdent",
                  PTY = 0,
                  TP = true,
                  TA = false,
                  REG = "don't mention min,max length"
                },
                signalChangeThreshold = 101
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
      --End Test case ResponseOutOfBoundCheck.2.29

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.30
      --Description: GetInteriorVehicleData with fanSpeed parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseFanSpeedOutUpperBound()
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
                level = 0
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
                fanSpeed = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.30

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.31
      --Description: GetInteriorVehicleData with currentTemp parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseCurrentTempOutUpperBound()
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
                level = 0
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
                currentTemp = 101,
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
      --End Test case ResponseOutOfBoundCheck.2.31

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.32
      --Description: GetInteriorVehicleData with desiredTemp parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseDesiredTempOutUpperBound()
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
                level = 0
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
                desiredTemp = 101,
                autoModeEnable = true,
                temperatureUnit = "CELSIUS"
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.32

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.33
      --Description: GetInteriorVehicleData with CT parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseCTOutLowerBound()
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
                level = 0
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-070",
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
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.33

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.34
      --Description: GetInteriorVehicleData with PTY parameter out of bounds
        function Test:GetInteriorVehicleData_ResponsePTYOutLowerBound()
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
                level = 0
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdent",
                  PTY = -1,
                  TP = true,
                  TA = false,
                  REG = "don't mention min,max length"
                },
                signalChangeThreshold = 10
              },
              moduleType = "RADIO",
              moduleZone =
              {
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.34

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.35
      --Description: GetInteriorVehicleData with PS parameter out of bounds
        function Test:GetInteriorVehicleData_ResponsePSOutUpperBound()
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
                level = 0
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
                  PS = "123456789",
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
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.35

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.36
      --Description: GetInteriorVehicleData with PI parameter out of bounds
        function Test:GetInteriorVehicleData_ResponsePIOutUpperBound()
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
                level = 0
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
                  RT = "Radio text minlength = 0, maxlength = 64",
                  CT = "2015-09-29T18:46:19-0700",
                  PI = "PIdentI",
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
                clospan = 1,
                row = 1,
                rowspan = 1,
                col = 1,
                levelspan = 1,
                level = 1
              }
            }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.36

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.37
      --Description: GetInteriorVehicleData with RT parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseRTOutUpperBound()
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
                level = 0
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
                        RT = "RADIO TEXT Minlength = 0, Maxlength = 64 RADIO TEXT Minlength = 6",
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
                  }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.37

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseOutOfBoundCheck.2.38
      --Description: GetInteriorVehicleData with CT parameter out of bounds
        function Test:GetInteriorVehicleData_ResponseCTOutUpperBound()
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
                level = 0
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
                        RT = "Radio text minlength = 0, maxlength = 64",
                        CT = "2015-09-29T18:46:19-07009",
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
                  }
              })
            end)

          --mobile side: expect GENERIC_ERROR response with info
          EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid response from the vehicle"})
        end
      --End Test case ResponseOutOfBoundCheck.2.38

  --End Test case ResponseOutOfBoundCheck.2
--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end