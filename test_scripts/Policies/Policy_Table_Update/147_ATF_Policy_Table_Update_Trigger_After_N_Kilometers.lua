---------------------------------------------------------------------------------------------
-- Requirement summary:
-- Request to update PT - after "N" kilometers
--
-- Description:
-- TIf SDL gets OnVehcileData ("odometer") notification from HMI and the difference between
-- between current "odometer" value_2 and "odometer" value_1 when the previous UpdatedPollicyTable was applied is
-- equal or greater than to the value of "exchange_after_x_kilometers" field ("module_config" section) of policies database,
-- the policies manager must request an update to its local policy table after "N" kilometers.
-- 1. Used preconditions:
-- a) device an app with app_ID is running is consented
-- b) application is running on SDL
-- c) The value of odometer received on previous PTU is "500"
-- d) the value in PT "module_config"->"'exchange_after_x_kilometers'":500
-- 2. Performed steps:
-- a) HMI->SDL:OnVehcileData ("odometer":1005)
--
-- Expected result:
-- a) Initiates PTU:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- PTS is created by SDL:
-- SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Functions ]]
local function UpdatePolicy()

  local PermissionForSubscribeVehicleData =
  [[
  "SubscribeVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ],
    "parameters" : ["odometer"]
  }
  ]].. ", \n"
  local PermissionForOnVehicleData =
  [[
  "OnVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ],
    "parameters" : ["odometer"]
  }
  ]].. ", \n"

  local PermissionLinesForBase4 = PermissionForSubscribeVehicleData..PermissionForOnVehicleData
  local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"SubscribeVehicleData","OnVehicleData"})
  testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
end
UpdatePolicy()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Activate_App_And_Consent_Device_To_Start_PTU()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, { result = {
        code = 0,
        isSDLAllowed = false},
      method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
            end)
          EXPECT_NOTIFICATION("OnPermissionsChange", {})
        end)
    end)
end

function Test:Preconditions_Set_Odometer_Value1()
  local cid_vehicle = self.mobileSession:SendRPC("SubscribeVehicleData", {odometer = true})
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        odometer = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_ODOMETER" }
      })
    end)
  EXPECT_RESPONSE(cid_vehicle, { success = true, resultCode = "SUCCESS" })
end

function Test:Precondition_Update_Policy_With_New_Exchange_After_X_Kilometers_Value()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "filename"
        }
      )
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY" },
          "files/jsons/Policies/Policy_Table_Update/exchange_after_1000_kilometers_ptu.json")
          local systemRequestId
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              systemRequestId = data.id
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                {
                  policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                })
              local function to_run()
                self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 800)
              self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
              EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
            end)
        end)
    end)
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", { odometer = true })
  :Do(function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { odometer = 1234 })
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Set_Odometer_Value_NO_PTU_Is_Triggered()
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {odometer = 2200})
  EXPECT_NOTIFICATION("OnVehicleData", {odometer = 2200})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}):Times(0)
end

function Test:TestStep_Set_Odometer_Value_And_Check_That_PTU_Is_Triggered()
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {odometer = 2250})
  EXPECT_NOTIFICATION("OnVehicleData", {odometer = 2250})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(AtLeast(1))
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
