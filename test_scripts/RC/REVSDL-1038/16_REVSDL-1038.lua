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

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

Test = require('connecttest')
require('cardinalities')

---------------------------------------------------------------------------------------------
-----------------------Requirement: HMI's RPCs validation rules------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

--NOTE: UPDATED "OnSetDriversDevice" to "OnDeviceRankChanged" base on Requirement
--=================================================BEGIN TEST CASES 16==========================================================--

  --Begin Test case ResponseFakeParamsNotification.16
  --Description:  --Fake params

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --<17.>In case HMI sends a notification, expected by RSDL for internal processing, with one or more fake params (that is, non-existent per HMI_API) to RSDL, RSDL must cut these fake params off and process the notification
            --Information: applicable RPCs:
            --OnSetDriversDevice
            --OnReverseAppsAllowing

      --Begin Test case ResponseFakeParamsNotification.16.1
      --Description: send notification with fake params
              --NOTE: UPDATED "OnSetDriversDevice" to "OnDeviceRankChanged" base on Requirement
        function Test:OnSetDriversDevice_FakeParamsInsideDevice()

          -- --hmi side: sending RC.OnSetDriversDevice notification
          -- self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {
                  -- device = {
                    -- fake1 = true,
                    -- name = "127.0.0.1",
                    -- fake2 = {1},
                    -- id = 1,
                    -- isSDLAllowed = true,
                    -- fake3 = "   fake params   "
                  -- }
              -- })

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", fake1 = true, device = {name = "127.0.0.1", fake2 = {1}, id = device1mac, isSDLAllowed = true, fake3 = "   fake params   "}})

          --mobile side: SDL does not send fake params to mobile app
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(1)

        end
      --End Test case ResponseFakeParamsNotification.16.1

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseFakeParamsNotification.16.2
      --Description: send notification with fake params
              --NOTE: UPDATED "OnSetDriversDevice" to "OnDeviceRankChanged" base on Requirement
        function Test:OnSetDriversDevice_FakeParamsOutsideDevice()

          -- --hmi side: sending RC.OnSetDriversDevice notification
          -- self.hmiConnection:SendNotification("RC.OnSetDriversDevice", {
                  -- fake1 = {1},
                  -- device = {
                    -- name = "127.0.0.1",
                    -- id = 1,
                    -- isSDLAllowed = true
                  -- }
              -- })

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {fake0 = "ERROR", deviceRank = "PASSENGER", fake1 = true, device = {name = "127.0.0.1", fake2 = {1}, id = device1mac, isSDLAllowed = true, fake3 = "   fake params   "}})

          --mobile side: SDL does not send fake params to mobile app
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(1)

        end
      --End Test case ResponseFakeParamsNotification.16.2

    -----------------------------------------------------------------------------------------

      --Begin Test case ResponseFakeParamsNotification.16.3
      --Description: send notification with fake params
        function Test:OnReverseAppsAllowing_FakeParams()

          --hmi side: sending VehicleInfo.OnReverseAppsAllowing notification
          self.hmiConnection:SendNotification("VehicleInfo.OnReverseAppsAllowing", {allowed = true, isAllowed = false})

          --mobile side: Absence of notifications
          EXPECT_NOTIFICATION("OnPermissionsChange")
          :Times(1)

        end
      --End Test case ResponseFakeParamsNotification.16.3

  --End Test case ResponseFakeParamsNotification.16
--=================================================END TEST CASES 16==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end