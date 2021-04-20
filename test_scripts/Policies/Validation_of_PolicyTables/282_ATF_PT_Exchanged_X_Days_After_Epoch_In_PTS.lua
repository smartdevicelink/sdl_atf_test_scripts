---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "pt_exchanged_x_days_after_epoch" at PolicyTable
--
-- Description:
-- Pollicies Manager must update "pt_exchanged_x_days_after_epoch" (Integer) section on each successful PolicyTable exchange.
-- Example of PolicyTable: "pt_exchanged_x_days_after_epoch" "policy_table":{"module_meta":{ "pt_exchanged_x_days_after_epoch": 46684, }}
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) App successfylly registered, Activates, consented, and updated
-- 2. Performed steps
-- a) Initiate new PTU to get PTS and validate pt_exchanged_x_days_after_epoch
--
-- Expected result:
-- a) pt_exchanged_x_days_after_epoch value is equal to time of successfully updating
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Variables ]]
local pathToSnapshot
local days_after_epoch_prev

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Local Functions ]]
local function getDaysAfterEpochFromPTS(pathToFile)
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  local daysAfterEpochFromPTS = data.policy_table.module_meta.pt_exchanged_x_days_after_epoch

  return daysAfterEpochFromPTS
end

local function getSystemDaysAfterEpoch()
  local function getTimezoneOffset(ts)
    local utcdate = os.date("!*t", ts)
    local localdate = os.date("*t", ts)
    localdate.isdst = false
    return os.difftime(os.time(localdate), os.time(utcdate))
  end
  local t = os.time()
  local ofs = getTimezoneOffset(t)
  return math.floor((t+ofs)/(60*60*24))
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Activate_App_Consent_Device_And_Update_Policy()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          -- GetCurrentTimeStampDeviceConsent()
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data1)
              self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
              :Do(function()
                end)
            end)
        end)
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      pathToSnapshot = data.params.file
      days_after_epoch_prev = getDaysAfterEpochFromPTS(pathToSnapshot)

      local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
          { policyType = "module_config", property = "endpoints" })
      EXPECT_HMIRESPONSE(requestId)
      :Do(function()
          self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{requestType = "PROPRIETARY", fileName = "filename"})
          EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
          :Do(function()
              local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/ptu_general.json")
              local systemRequestId
              EXPECT_HMICALL("BasicCommunication.SystemRequest")
              :Do(function(_,data1)
                  systemRequestId = data1.id
                  self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                    {
                      policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                    })
                  self.hmiConnection:SendResponse(systemRequestId, "BasicCommunication.SystemRequest", "SUCCESS", {})
                  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}):Timeout(500)
                  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
                end)
            end)
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Initiate_PTU_And_Check_Days_After_Epoch_In_PTS()
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate")
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :ValidIf(function()
    local system_time = getSystemDaysAfterEpoch()
    local days_after_epoch_current = getDaysAfterEpochFromPTS(pathToSnapshot)

      if( days_after_epoch_current ~= (days_after_epoch_prev + 1)*system_time ) then
        self:FailTestCase("Days_after_epoch are not changed. Previous: " .. days_after_epoch_prev .. ", Current: " .. days_after_epoch_current)
      end

      if getDaysAfterEpochFromPTS(pathToSnapshot) == getSystemDaysAfterEpoch() then return true
      else
        self:FailTestCase("Wrong days after epoch. Expected: " .. system_time .. ", Actual: " .. days_after_epoch_current)
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
