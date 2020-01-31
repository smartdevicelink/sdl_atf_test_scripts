---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PTU validation rules
--
-- Check SDL behavior in case optional parameter absent/present in received PTU snapshot
-- 1. Used preconditions:
-- Do not start default SDL
-- Prepare PTU file with omitted and with all required fields
-- Start SDL
-- InitHMI register MobileApp
-- Perform PT update
--
-- 2. Performed steps:
-- Check that that PTU correctly performed and omitted parameters were ignored
--
-- Expected result:
-- SDL must validate the Policy Table Update (policyFile) according to Data Dictiona dictionary) statuses of optional, required, or omitted:
--1) The validation should not reject tables that include fields with a status of ‘omitted,’ it will assume these are to be ignored.
--2) Validation must reject a policy table update if it does not include fields with a status of ‘required.’
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
-- local json = require("modules/json")
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicySDLErrorsStops = require ('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General configuration parameters ]]
Test = require('connecttest')
local config = require('config')
config.defaultProtocolVersion = 2

require('cardinalities')
require('user_modules/AppTypes')

--[[ Local Variables ]]
local HMIAppId
local ptuAppRegistered = "files/ptu_app.json"

--[[ Local Functions ]]
function Test:updatePolicyInDifferentSessions(_, appName, mobileSession)
  local iappID = self.applications[appName]
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"} )

      mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_,_)
          local CorIdSystemRequest = mobileSession:SendRPC("SystemRequest",
            {
              fileName = "PolicyTableUpdate",
              requestType = "PROPRIETARY",
              appID = iappID
            },
          "files/jsons/Policies/PTU_ValidationRules/PTU_has_omitted.json")

          local systemRequestId
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,_data1)
              systemRequestId = _data1.id
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"} )
              local function to_run()
                self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end

              RUN_AFTER(to_run, 500)
            end)
          mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ActivateApp()
  HMIAppId = self.applications[config.application1.registerAppInterfaceParams.appName]

  commonSteps:ActivateAppInSpecificLevel(Test, HMIAppId)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data3)
      self.hmiConnection:SendResponse(data3.id, data3.method, "SUCCESS", {})
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:UpdatePolicy_ExpectOnAppPermissionChangedWithAppID()
  self:updatePolicyInDifferentSessions(ptuAppRegistered,
    config.application1.registerAppInterfaceParams.appName,
    self.mobileSession)
end

function Test:TestStep_CheckSDLLogError()
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Errors: policy_table.policy_table.module_config.preloaded_date: should be omitted in PT_UPDATE")
  if (result == false) then
    self:FailTestCase("Error: message 'Errors: policy_table.policy_table.module_config.preloaded_date: should be omitted in PT_UPDATE' is not observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
