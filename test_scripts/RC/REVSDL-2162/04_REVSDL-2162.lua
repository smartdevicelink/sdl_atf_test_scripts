local commonSteps = require("user_modules/shared_testcases/commonSteps")
commonSteps:CheckSDLPath()
commonSteps:DeleteLogsFileAndPolicyTable()

local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
commonPreconditions:ReplaceFile("sdl_preloaded_pt.json", "./files/jsons/RC/rc_2164_sdl_preloaded_pt.json")

local revsdl = require("user_modules/revsdl")

revsdl.AddUnknownFunctionIDs()
revsdl.SubscribeToRcInterface()
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.appID = "8675311"

Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice

--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()

local appid = "1"

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
----------Requirement: GetInteriorVehicleDataCapabilies - rules for policies checks----------
---------------------------------------------------------------------------------------------
--=========================================================================================--



--===============PLEASE USE PT FILE: "sdl_preloaded_pt.json" UNDER: \TestData\Requirement\ FOR THIS SCRIPT=====================--


--=================================================BEGIN TEST CASES 4==========================================================--
  --Begin Test suit CommonRequestCheck.4 for Req.#4

  --Description: 4. In case   a. remote-control driver's app sends GetInteriorVehicleDataCapabilities request (with any set of parameters)
                -- RSDL must check this app's assigned policies and transfer only allowed moduleTypes via RC.GetInteriorVehicleDataCapabilities to the vehicle

  --Begin Test case CommonRequestCheck.4.1
  --Description:  RSDL must check this app's assigned policies and transfer only allowed moduleTypes via RC.GetInteriorVehicleDataCapabilities to the vehicle

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        -- RSDL must check this app's assigned policies and transfer only allowed moduleTypes via RC.GetInteriorVehicleDataCapabilities to the vehicle

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.4.1
      --Description: Register new session for register new apps
        function Test:TC4_NewApps()

          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)

        end
      --End Test case Precondition.4.1

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.4.1
      --Description: Register new session for register new apps
        function Test:TC4_RegisterAppID()

          --mobile side: RegisterAppInterface request
            self.mobileSession1:StartService(7)
            :Do(function()
             local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
                 {

                syncMsgVersion =
                {
                 majorVersion = 2,
                 minorVersion = 2,
                },
                appName ="App1",
                ttsName =
                {

                  {
                    text ="Testes",
                    type ="TEXT",
                  },
                },
                vrSynonyms =
                {
                  "Testes",
                },
                isMediaApplication = true,
                languageDesired ="EN-US",
                hmiDisplayLanguageDesired ="EN-US",
                appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                appID = appid,

                 })

            EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
            {
              application =
              {
              appName = "App1"
              }
            })
            :Do(function(_,data)
              self.applications["App1"] = data.params.application.appID
              ID = data.params.application.appID
            end)


             --mobile side: RegisterAppInterface response
             self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"},
              {

                syncMsgVersion =
                {
                 majorVersion = 2,
                 minorVersion = 2,
                },
                appName ="App1",
                ttsName =
                {

                  {
                    text ="Testes",
                    type ="TEXT",
                  },
                },
                vrSynonyms =
                {
                  "Testes",
                },
                isMediaApplication = true,
                languageDesired ="EN-US",
                hmiDisplayLanguageDesired ="EN-US",
                appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                appID = appid,

              }
             )

            --mobile side: Expect OnPermissionsChange notification for Passenger's device
            self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )
          end)

        end
      --End Test case Precondition.4.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.1
      --Description: Set device1 to Driver's device from HMI
        function Test:OnDeviceRankChanged_Driver()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.4.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.2
      --Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
        function Test:AutoAllow_DriverRADIO()
          local cid = self.mobileSession1:SendRPC("GetInteriorVehicleDataCapabilities",
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
            moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
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
                                  row = 0,
                                  rowspan = 2,
                                  col = 0,
                                  levelspan = 1,
                                  level = 0
                                },
                                moduleType = "RADIO"
                              },
                              {
                                moduleZone = {
                                  colspan = 2,
                                  row = 0,
                                  rowspan = 2,
                                  col = 0,
                                  levelspan = 1,
                                  level = 0
                                },
                                moduleType = "RADIO"
                              }
                            }
            })
          end)

          --mobile side: expect SUCCESS response
          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
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
                                                },
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
      --End Test case CommonRequestCheck.4.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.3
      --Description: application sends GetInteriorVehicleDataCapabilities as Driver and without ModuleType
        function Test:AutoAllow_DriverWithoutModuleType()
          local cid = self.mobileSession1:SendRPC("GetInteriorVehicleDataCapabilities",
          {
            zone =
            {
              colspan = 2,
              row = 0,
              rowspan = 2,
              col = 0,
              levelspan = 1,
              level = 0
            }
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
                                  row = 0,
                                  rowspan = 2,
                                  col = 0,
                                  levelspan = 1,
                                  level = 0
                                },
                                moduleType = "RADIO"
                              }
                            }
            })
          end)

          --mobile side: expect SUCCESS response
          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
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
      --End Test case CommonRequestCheck.4.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.3
      --Description: application sends GetInteriorVehicleDataCapabilities missing zone and ModuleType
        function Test:AutoAllow_MissingZoneAndModuleType()
          local cid = self.mobileSession1:SendRPC("GetInteriorVehicleDataCapabilities",
          {

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
                                  row = 0,
                                  rowspan = 2,
                                  col = 0,
                                  levelspan = 1,
                                  level = 0
                                },
                                moduleType = "RADIO"
                              }
                            }
            })
          end)

          --mobile side: expect SUCCESS response
          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
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
      --End Test case CommonRequestCheck.4.1.3

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.4.1


--=================================================END TEST CASES 4==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end