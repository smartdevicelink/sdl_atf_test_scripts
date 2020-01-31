---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "pt_exchanged_at_odometer_x" storage into PolicyTable
--
-- Description:
-- Storing value in 'pt_exchanged_at_odometer_x' section of LocalPT
-- 1. Used preconditions:
-- Delete log file and policy table if any
-- Start SDL and HMI
-- Register app
-- Activate app-> PTU is triggered
--
-- 2. Performed steps
-- Check "pt_exchanged_at_odometer_x" value of LocalPT
--
-- Expected result:
-- Pollicies Manager requests the value of 'pt_exchanged_at_odometer_x' via VehicleInfo.GetVehicleData ("odometer");
-- <odometer> value must be stored in LocalPT in "pt_exchanged_at_odometer_x" of "meta_data" section
---------------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Activate_app()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId,{})
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= true then
        local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestIdGetMes)
        :Do(function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
            EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
            :Do(function(_,data3)
                self.hmiConnection:SendResponse(data3.id, data3.method, "SUCCESS", {})
              end)
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data1)
                self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
          end)
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
end

function Test:Precondition_PolicyUpdateRAI()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "filename"})

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY" },
          "files/jsons/Policies/PTU_ValidationRules/ptu_RAI.json")
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate" })

              EXPECT_HMICALL("VehicleInfo.GetVehicleData", { odometer = true })
              :Do(function(_,data)
                  --print("VehicleInfo.GetVehicleData is received")
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {odometer = 100})
                end)
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Check_pt_exchanged_at_odometer_x_stored_in_PT()
  local query
  if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
    query = "sqlite3 " .. config.pathToSDL .. "storage/policy.sqlite".. " \"select pt_exchanged_at_odometer_x from module_meta\""
  elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
    query = "sqlite3 " .. config.pathToSDL .. "policy.sqlite".. " \"select pt_exchanged_at_odometer_x from module_meta\""
  else commonFunctions:userPrint(31, "policy.sqlite is not found")
  end
  if query ~= nil then
    os.execute("sleep 3")
    local handler = io.popen(query, 'r')
    os.execute("sleep 1")
    local result = handler:read( '*l' )
    handler:close()
    --print("result: "..result)
    if result == tostring(100) then
      return true
    else
      self:FailTestCase("pt_exchanged_at_odometer_x in DB has wrong value: " .. tostring(result))
      return false
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
