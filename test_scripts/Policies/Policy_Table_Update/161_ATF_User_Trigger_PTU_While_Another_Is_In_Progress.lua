---------------------------------------------------------------------------------------------
-- Requirement summary:
-- User triggering PTU while another PTU request is still in progress
--
-- Description:
-- If a user triggers a policy table update while another request is currently in progress (in the timeout window),
-- Policy Manager must wait for a response from the current on-going request/times-out/succeed, before the new one request will be sent out.​
-- 1. Used preconditions:
-- a) SDL and HMI are running
-- b) App is connected to SDL.
-- c) The device the app is running on is consented
-- d) Policy Table Update procedure is in progress (merge of received PTU not yet happend)
-- 2. Performed steps:
-- a) User initiates PT Update from HMI (press the appropriate button) HMI->SDL: SDL.UpdateSDL
--
-- Expected result:
-- a) SDL->HMI:SDL.UpdateSDL()
-- b) Policy Manager must wait for a response from the current on-going PTU request/times-out/succeed
-- c) PoliciesManager starts the PTU sequence:
-- d) PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

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
              :Do(function()

                end)
            end)
          EXPECT_NOTIFICATION("OnPermissionsChange", {})
        end)
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Start_Update_First_Time_And_Trigger_New_PTU_Via_UpdateSDL()
  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetURLS" } } )
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON" } )
      :Do(function(_,_)
          -- Reuest for new PTU
          local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
          EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL"}})

          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"},
          "files/ptu_general.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest",{
              requestType = "PROPRIETARY",
              fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})

              EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}, { status = "UPDATE_NEEDED" }):Times(2)
              :Do(function(e, d)
                  if (e.occurences == 2) and (d.params.status == "UPDATE_NEEDED") then
                    EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
                  end
                end)
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
