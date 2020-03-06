---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [OnAppPermissionChanged]: appRevoked:true
--
-- Description:
-- In case the app is currently registered and in any
-- HMILevel and in result of PTU gets "null" policies,
-- SDL must send OnAppPermissionChanged (appRevoked: true) to HMI
--
-- Used preconditions:
-- appID="123abc" is registered to SDL
-- any PolicyTableUpdate trigger happens
--
-- Performed steps:
-- PTU is valid -> application with appID=123abc gets "null" policy
--
-- Expected result:
-- SDL -> HMI: OnAppPermissionChanged (<appID>, appRevoked=true, params)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
-- local mobileSession = require("mobile_session")
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local json = require("modules/json")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local ptu_table

--[[ Local Functions ]]
local function ptsToTable(pts_f)
  local f = io.open(pts_f, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

local function updatePTU(ptu)
  if ptu.policy_table.consumer_friendly_messages.messages then
    ptu.policy_table.consumer_friendly_messages.messages = nil
  end
  ptu.policy_table.device_data = nil
  ptu.policy_table.module_meta = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies["0000001"] = json.null
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  ptu.policy_table.module_config.preloaded_pt = nil
  ptu.policy_table.vehicle_data = nil
end

local function storePTUInFile(ptu, ptu_file_name)
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ActivateApp()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, data1)
      if data1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, data2)
                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
              end)
            :Times(1)
          end)
      end
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, d)
      ptu_table = ptsToTable(d.params.file)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:PTU()
  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name})
      updatePTU(ptu_table)
      storePTUInFile(ptu_table, ptu_file_name)
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function()
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name}, ptu_file_name)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, d)
              self.hmiConnection:SendResponse(d.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", { appRevoked = true, appID = self.applications["Test Application"]})
        end)
    end)
  os.remove(ptu_file_name)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
