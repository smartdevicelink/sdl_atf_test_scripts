---------------------------------------------------------------------------------------------
-- Requirement summary:
--    [Policies] "default" policies and "groups" validation
--
-- Description:
--     Validation of "groups sub-section in "default" if "default" policies assigned to the application.
--     1. Used preconditions:
--      SDL and HMI are running
--      Delete logs file and policy table
--      Activate app
--
--     2. Performed steps
--      Perform PTU
--
-- Expected result:
--     PoliciesManager must validate "groups" sub-section in "default" and treat it as valid -> PTU is valid
---------------------------------------------------------------------------------------------
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

function Test:Precondition_Activate_app()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if data.result.isSDLAllowed ~= true then
      local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetMes)
      :Do(function()
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data1)
          self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
      end)
    end
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Validate_groups_in_default_upon_PTU()
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS)
  :Do(function(_,data)
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
    {
      requestType = "PROPRIETARY",
      fileName = "filename"
    }
    )
    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
    :Do(function()
      local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
      {
        fileName = "PolicyTableUpdate",
        requestType = "PROPRIETARY"
      }, "files/PTU_UpdateDefaultGroups.json")
      local systemRequestId
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function()
        systemRequestId = data.id
        self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
        {
          policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
        })
        local function to_run()
          self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
        end
        RUN_AFTER(to_run, 500)
      end)
      self.mobileSession:ExpectResponse(CorIdSystemRequest, {})
    end)
  end)
   --PTU is valid
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    {status = "UPDATING"}, {status = "UP_TO_DATE"}):Times(2)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
