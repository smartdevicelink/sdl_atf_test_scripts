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
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()


--======================================Requirement=========================================--
---------------------------------------------------------------------------------------------
-----------Requirement: RSDL must inform HMILevel of a rc-application to HMI ----------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test suit CommonRequestCheck.2 for Req.#2

  --Description: 2. In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from passenger's device is changed (see Requirement for details), RSDL must inform this event via BC.ActivateApp (level: <appropriate assigned HMILevel of the app>) to HMI.
            --Exception: FULL level (that is, RSDL must not notify HMI about the rc-app has transitioned to FULL).


  --Begin Test case CommonRequestCheck.2.1
  --Description:  In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from passenger's device is changed (see Requirement for details), RSDL must inform this event via BC.ActivateApp (level: <appropriate assigned HMILevel of the app>) to HMI.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from passenger's device is changed to NONE, RSDL must inform this event via BC.ActivateApp (level: NONE) to HMI.

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.2.1.1
      --Description: Register new session for register new app
        function Test:TC1_Precondition1()
          self.mobileSession1 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
        end
      --End Test case Precondition.2.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1.2
      --Description: RSDL sends BC.ActivateApp (level: NONE) to HMI
          function Test:TC1_Driver_LevelNONE()
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

                EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
                {
                  application =
                  {
                  appName = "Test Application1"
                  }
                })
                :Do(function(_,data)
                  self.applications["Test Application1"] = data.params.application.appID

                  --RSDL sends BC.ActivateApp (level: NONE) to HMI.
                  EXPECT_HMICALL("BasicCommunication.ActivateApp",
                  {
                    appID = self.applications["Test Application1"],
                    level = "NONE",
                    priority = "NONE"
                  })

                end)

                --SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
                self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

                --mobile side: Expect OnPermissionsChange notification for Passenger's device
                self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

                --mobile side:RSDL sends OnHMIStatus (NONE,params) to mobile application.
                self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
                :Times(2)
              end)
            end
      --End Test case CommonRequestCheck.2.1.2
    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.2.1

  --Begin Test case CommonRequestCheck.2.2
  --Description:  In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from passenger's device is changed to BACKGROUND, RSDL must inform this event via BC.ActivateApp (level: BACKGROUND) to HMI.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from passenger's device is changed to BACKGROUND, RSDL must inform this event via BC.ActivateApp (level: BACKGROUND) to HMI.

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.2.1
      --Description: application sends ButtonPress as Driver and ModuleType = CLIMATE to get HMILevel = BACKGROUND
        function Test:TC2_PassengerBACKGROUND()
          local cid = self.mobileSession1:SendRPC("ButtonPress",
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
                        col = 1,
                        levelspan = 1,
                        level = 0
                      },
                      moduleType = "CLIMATE",
                      buttonPressMode = "LONG",
                      buttonName = "AC_MAX"
                    })
              :Do(function(_,data)

                --RSDL sends BC.ActivateApp (level: BACKGROUND) to HMI.
                EXPECT_HMICALL("BasicCommunication.ActivateApp",
                {
                  appID = self.applications["Test Application1"],
                  level = "BACKGROUND",
                  priority = "NONE"
                })
                --hmi side: sending Buttons.ButtonPress response
                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
              end)


          --SDL sends (success:true) with the following resultCodes: SUCCESS
          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

          --mobile side:RSDL sends OnHMIStatus (NONE,params) to mobile application.
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })

        end
      --End Test case CommonRequestCheck.2.2.1

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.2.2


  --Begin Test case CommonRequestCheck.2.3
  --Description:  In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from passenger's device is changed to LIMITED, RSDL must inform this event via BC.ActivateApp (level: LIMITED) to HMI.

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --In case the HMILevel of the application registered with "REMOTE_CONTROL" appHMIType from passenger's device is changed to LIMITED, RSDL must inform this event via BC.ActivateApp (level: LIMITED) to HMI.

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.3.1
      --Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
        function Test:TC3_PassengerLIMITED()
          --mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
          local cid = self.mobileSession1:SendRPC("ButtonPress",
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

          --hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
          EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
                {
                  appID = self.applications["Test Application1"],
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


              --RSDL sends BC.ActivateApp (level: LIMITED) to HMI.
              EXPECT_HMICALL("BasicCommunication.ActivateApp",
              {
                appID = self.applications["Test Application1"],
                level = "LIMITED",
                priority = "NONE"
              })
              :Do(function(_,_)
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
                  :Do(function(_,data1)
                    --hmi side: sending Buttons.ButtonPress response
                    self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
                  end)
              end)
          end)

          --SDL sends (success:true) with the following resultCodes: SUCCESS
          self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

          --mobile side:RSDL sends OnHMIStatus (NONE,params) to mobile application.
          self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE" })
        end
      --End Test case CommonRequestCheck.2.3.1

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.2.3

--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end