---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU] Trigger: kilometers
--
-- Description:
-- If SDL is subscribed via SubscribeVehicleData(odometer) right after ignition on, SDL gets OnVehcileData ("odometer") notification from HMI
-- and the difference between current "odometer" value_2 and "odometer" value_1 when the previous UpdatedPollicyTable was applied is equal or 
-- greater than to the value of "exchange_after_x_kilometers" field ("module_config" section) of policies database, SDL must trigger a 
-- PolicyTableUpdate sequence
-- 1. Used preconditions:
--   SDL is built with "-DEXTENDED_POLICY: HTTP" flag
--   The odometer value was "1234" when previous PTU was successfully applied. 
--   Policies DataBase contains "exchange_after_x_kilometers" = 1000
-- 2. Performed steps: 
-- SDL->HMI: Vehicleinfo.SubscribeVehicleData ("odometer")
-- HMI->SDL: Vehicleinfo.SubscribeVehicleData (SUCCESS)
-- user sets odometer to 2200
-- HMI->SDL: Vehicleinfo.OnVehicleData ("odometer:2200")
-- SDL: checks wether amount of kilometers sinse previous update is equal or greater "exchange_after_x_kilometers"
-- user sets odometer to 2250
-- HMI->SDL: Vehicleinfo.OnVehicleData ("odometer:2250")
-- SDL: checks wether amount of kilometers sinse previous update is equal or greater "exchange_after_x_kilometers"
-- SDL->HMI: OnStatusUpdate (UPDATE_NEEDED)
--
-- Expected result:
-- PTU flow started
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')

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
require("user_modules/AppTypes")
require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Activate_App_Start_PTU()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"], level = "FULL"})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= true then
        RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data2)
                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(2)
          end)
        EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN" })
      end
    end)
end

function Test:Preconditions_Set_Odometer_Value1()
  local cidVehicle = self.mobileSession:SendRPC("SubscribeVehicleData", {odometer = true})
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)

  EXPECT_RESPONSE(cidVehicle, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {odometer = 1234})
      EXPECT_NOTIFICATION("OnVehicleData", {odometer = 1234})
    end)
end

function Test.Precondition_Update_Policy_With_New_Exchange_After_X_Kilometers_Value()
  commonFunctions:check_ptu_sequence_fully(Test, "files/jsons/Policies/Policy_Table_Update/odometer_ptu.json", "PolicyTableUpdate")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Set_Odometer_Value_NO_PTU_Is_Triggered()
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {odometer = 2200})
  EXPECT_NOTIFICATION("OnVehicleData", {odometer = 2200})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}):Times(0)
end

function Test.TestStep_Set_Odometer_Value_And_Check_That_PTU_Is_Triggered()
  commonFunctions:trigger_ptu_by_odometer(Test)
end

function Test.TestStep_Update_Policy_With_New_Exchange_After_X_Kilometers_Value()
  commonFunctions:check_ptu_sequence_fully(Test, "files/jsons/Policies/Policy_Table_Update/odometer_ptu.json", "PolicyTableUpdate")
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postconditions")

testCasesForPolicyTable:Restore_preloaded_pt()

function Test.Postcondition_Stop()
  StopSDL()
end

return Test