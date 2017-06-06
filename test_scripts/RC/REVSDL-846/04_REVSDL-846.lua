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
local mobile_session = require('mobile_session')

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"


--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
-------------------------Requirement: R-SDL must inform the app when the ---------------------
---------------------"driver's"/"passenger's" state of the device is changed-----------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 4==========================================================--
  --Begin Test suit CommonRequestCheck.4 for Req.#4

  --Description: 4. In case the device's state is changed from "passenger's" to "driver's", RSDL must leave all remote-control applications from this device in the same HMILevel as they were (that is, not send OnHMIStatus notification).


  --Begin Test case CommonRequestCheck.4
  --Description:  In case the device's state is changed from "passenger's" to "driver's", RSDL must leave all remote-control applications from this device in the same HMILevel as they were (that is, not send OnHMIStatus notification).

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --4. In case the device's state is changed from "passenger's" to "driver's", RSDL must leave all remote-control applications from this device in the same HMILevel as they were (that is, not send OnHMIStatus notification).

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.4.1
      --Description: Register new session for register new apps
        function Test:TC4_Step1_1()

          --New session1
          self.mobileSession1 = mobile_session.MobileSession(
            self,
            self.mobileConnection)

          --New session2
          self.mobileSession2 = mobile_session.MobileSession(
            self,
            self.mobileConnection)

          --New session3
          self.mobileSession3 = mobile_session.MobileSession(
            self,
            self.mobileConnection)

        end
      --End Test case Precondition.4.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.2
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=1 to SDL.
          function Test:TC4_Step1_2()
            self.mobileSession1:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
                {
                  syncMsgVersion =
                  {
                  majorVersion = 3,
                  minorVersion = 0
                  },
                  appName = "Test Application1",
                  isMediaApplication = true,
                  languageDesired = 'EN-US',
                  hmiDisplayLanguageDesired = 'EN-US',
                  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                  appID = "1"
                })

                --SDL sends OnAppRegistered (appID_1, REMOTE_CONTROL, params).
                EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
                {
                  application =
                  {
                  appName = "Test Application1"
                  }
                })
                :Do(function(_,data)
                  self.applications["Test Application1"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
                self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

                --SDL assign Level (NONE) and returns to mobile: OnHMIStatus (NONE, params)
                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2)
              end)
            end
      --End Test case CommonRequestCheck.4.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.3
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=2 to SDL.
          function Test:TC4_Step1_3()
            self.mobileSession2:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface",
                {
                  syncMsgVersion =
                  {
                  majorVersion = 3,
                  minorVersion = 0
                  },
                  appName = "Test Application2",
                  isMediaApplication = true,
                  languageDesired = 'EN-US',
                  hmiDisplayLanguageDesired = 'EN-US',
                  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                  appID = "2"
                })

                --SDL sends OnAppRegistered (appID_2, REMOTE_CONTROL, params).
                EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
                {
                  application =
                  {
                  appName = "Test Application2"
                  }
                })
                :Do(function(_,data)
                  self.applications["Test Application2"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
                self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

                --SDL assign Level (NONE) and returns to mobile: OnHMIStatus (NONE, params)
                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2)
              end)
            end
      --End Test case CommonRequestCheck.4.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.4
      --Description: From mobile app send RegisterAppInteface (REMOTE_CONTROL, params) with AppId=3 to SDL.
          function Test:TC4_Step1_4()
            self.mobileSession3:StartService(7)
            :Do(function()
                local CorIdRegister = self.mobileSession3:SendRPC("RegisterAppInterface",
                {
                  syncMsgVersion =
                  {
                  majorVersion = 3,
                  minorVersion = 0
                  },
                  appName = "Test Application3",
                  isMediaApplication = true,
                  languageDesired = 'EN-US',
                  hmiDisplayLanguageDesired = 'EN-US',
                  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
                  appID = "3"
                })

                --SDL sends OnAppRegistered (appID_3, REMOTE_CONTROL, params).
                EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
                {
                  application =
                  {
                  appName = "Test Application3"
                  }
                })
                :Do(function(_,data)
                  self.applications["Test Application3"] = data.params.application.appID
                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
                self.mobileSession3:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

                --SDL assign Level (NONE) and returns to mobile: OnHMIStatus (NONE, params)
                --check OnHMIStatus with deviceRank = "PASSENGER"
                self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2)

              end)
            end
      --End Test case CommonRequestCheck.4.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.5
      --Description: App2 (LIMITED)
          function Test:TC4_Step1_5()

              local cid = self.mobileSession2:SendRPC("ButtonPress",
              {
                zone =
                {
                  colspan = 2,
                  row = 0,
                  rowspan = 2,
                  col = 1,
                  levelspan = 1,
                  level = 0
                },
                moduleType = "RADIO",
                buttonPressMode = "LONG",
                buttonName = "VOLUME_UP"
              })

              --hmi side: expect RC.GetInteriorVehicleDataConsent request
              EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                    {
                      appID = self.applications["Test Application2"],
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
                --hmi side: sending RC.GetInteriorVehicleDataConsent response
                self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

                  --hmi side: expect Buttons.ButtonPress request
                  EXPECT_HMICALL("Buttons.ButtonPress",
                          {
                            zone =
                            {
                              colspan = 2,
                              row = 0,
                              rowspan = 2,
                              col = 1,
                              levelspan = 1,
                              level = 0
                            },
                            moduleType = "RADIO",
                            buttonPressMode = "LONG",
                            buttonName = "VOLUME_UP"
                          })
                    :Do(function(_,data)
                      --hmi side: sending Buttons.ButtonPress response
                      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                    end)

              end)

              --mobile side: SDL sends (success:true) with the following resultCodes: SUCCESS
              self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

              --SDL assign Level (LIMITED) and returns to mobile: OnHMIStatus (LIMITED, params)
              self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })

          end
      --End Test case CommonRequestCheck.4.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.6
      --Description: App3 (BACKGROUND)
          function Test:TC4_Step1_6()

              local cid = self.mobileSession3:SendRPC("ButtonPress",
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
                moduleType = "CLIMATE",
                buttonPressMode = "LONG",
                buttonName = "AC_MAX"
              })

            --hmi side: expect Buttons.ButtonPress request
            EXPECT_HMICALL("Buttons.ButtonPress",
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
                      moduleType = "CLIMATE",
                      buttonPressMode = "LONG",
                      buttonName = "AC_MAX"
                    })
              :Do(function(_,data)
                --hmi side: sending Buttons.ButtonPress response
                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
              end)

              self.mobileSession3:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

              --SDL assign Level (BACKGROUND) and returns to mobile: OnHMIStatus (BACKGROUND, params)
              self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })

          end
      --End Test case CommonRequestCheck.4.6

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.7
      --Description: From appropriate HMI menu set connected device as Driver's device.
        function Test:TC4_Step2()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device for App1, App2, App3
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession2:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )
          self.mobileSession3:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER" for App1, App2, App3
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", deviceRank = "DRIVER" })
          self.mobileSession3:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.4.7

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.4

--=================================================END TEST CASES 4==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end