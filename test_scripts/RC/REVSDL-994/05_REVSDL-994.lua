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
------------Requirement: HMILevel change for rc-apps from driver's device---------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--groups_PrimaryRC Group
local arrayGroups_PrimaryRC =  revsdl.arrayGroups_PrimaryRC()
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--=================================================BEGIN TEST CASES 5==========================================================--
  --Begin Test suit CommonRequestCheck.5 for Req.#5

  --Description: 5. In case an application with AppHMIType "REMOTE_CONTROL" from driver's device is in any of NONE, BACKGROUND or LIMITED HMILevel and RSDL receives SDL.ActivateApp for this application (= the vehicle HMI User activates this application from the HMI), RSDL must assign FULL HMILevel to this application and send it OnHMIStatus (FULL, params) notification


  --Begin Test case CommonRequestCheck.5.1
  --Description:  In case an application with AppHMIType "REMOTE_CONTROL" from driver's device is in any of NONE, BACKGROUND or LIMITED HMILevel and RSDL receives SDL.ActivateApp for this application (= the vehicle HMI User activates this application from the HMI), RSDL must assign FULL HMILevel to this application and send it OnHMIStatus (FULL, params) notification

    --Requirement/Diagrams id in jira:
        --Requirement
        --TC: Requirement

    --Verification criteria:
        --NONE to FULL

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.5.1.1
      --Description: Set device1 to Driver's device from HMI.
        function Test:TC5_Precondition1()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case Precondition.5.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.2
      --Description: activate App1 from NONE to FULL
        function Test:TC5_App1NONEToFULL()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.5.1.2

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.3
      --Description: Set HMILevel App1 to LIMITED
        function Test:TC5_Precondition2()

          --HMI sends to SDL: OnAppDeactivated (appID_1, *GENERAL*).
          self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

          --App1 side: changing HMILevel to LIMITED
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "LIMITED"})
          :Timeout(5000)

        end
      --End Test case CommonRequestCheck.5.1.3

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.4
      --Description: activate App1 from LIMITED to FULL
        function Test:TC5_App1LIMITEDToFULL()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.5.1.4

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.5
      --Description: Set device1 from Driver's to passenger's device (precondition for setting to HMILevel BACKGROUND)
        function Test:TC5_Precondition3()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
          {deviceRank = "PASSENGER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for passenger's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "PASSENGER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"}, { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })
          :Times(2)
        end
      --End Test case CommonRequestCheck.5.1.5

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.6
      --Description: application sends ButtonPress as Driver and ModuleType = RADIO, buttonPressMode = LONG (BACKGROUND)
        function Test:TC5_Precondition4()
          local cid = self.mobileSession:SendRPC("ButtonPress",
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
            moduleType = "RADIO",
            buttonPressMode = "LONG",
            buttonName = "VOLUME_UP"
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
                  moduleType = "RADIO",
                  buttonPressMode = "LONG",
                  buttonName = "VOLUME_UP"
                })
          :Do(function(_,data)
            --hmi side: sending Buttons.ButtonPress response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          end)

          --Mobile side: RSDL sends OnHMIStatus (BACKGROUND,params)
          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})

          EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        end
      --End Test case CommonRequestCheck.5.1.6

    -----------------------------------------------------------------------------------------

      --Begin Test case Precondition.5.1.7
      --Description: Set device1 to Driver's device from HMI.
        function Test:TC5_Precondition5()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case Precondition.5.1.7

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.5.1.8
      --Description: activate App1 from BACKGROUND to FULL
        function Test:TC5_App1BACKGROUNDToFULL()

          --hmi side: sending SDL.ActivateApp request
          local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",
                                { appID = self.applications["Test Application"] })

          --hmi side: Waiting for SDL.ActivateApp response
          EXPECT_HMIRESPONSE(rid)

          self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL"})
        end
      --End Test case CommonRequestCheck.5.1.8

    -----------------------------------------------------------------------------------------
  --End Test case CommonRequestCheck.5.1

--=================================================END TEST CASES 5==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end