---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [GENIVI] [Policy] "Proprietary" flow:
-- SDL must be build with "-DEXTENDED_POLICY: PROPRIETARY"
--
-- Description:
-- To "switch on" the "Proprietary" flow of PolicyTableUpdate feature
-- -> SDL should be built with -DEXTENDED_POLICY: PROPRIETARY flag
-- 1. Performed steps
-- Build SDL with flag above
--
-- Expected result:
-- SDL is successfully built
-- The flag EXTENDED_POLICY is set to ROPRIETARY
-- PTU passes successfully

---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")

--[[ Local Variables ]]
local app_id = config.application1.registerAppInterfaceParams.fullAppID
local ptu_table

--[[ Local Functions ]]
local function ptsToTable(pts_f)
  local f = io.open(pts_f, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

local function updatePTU(ptu)
  ptu.policy_table.consumer_friendly_messages.messages = nil
  ptu.policy_table.device_data = nil
  ptu.policy_table.module_meta = nil
  ptu.policy_table.vehicle_data = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies[app_id] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies[app_id]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  ptu.policy_table.module_config.preloaded_pt = nil
end

local function storePTUInFile(ptu, ptu_file_name)
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

local function ptuSequence(self)
  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(
    function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
      updatePTU(ptu_table)
      storePTUInFile(ptu_table, ptu_file_name)
      self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(
        function()
          local corIdSystemRequest = self.mobileSession1:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(
            function(_, d2)
              self.hmiConnection:SendResponse(d2.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
            end)
          self.mobileSession1:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)
  os.remove(ptu_file_name)
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require("user_modules/AppTypes")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:RAI_PTU()
  local corId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      self.applications[config.application1.registerAppInterfaceParams.fullAppID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, {status = "UP_TO_DATE" })
      :Times(3)
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
      :Do(
        function(_, d2)
          ptu_table = ptsToTable(d2.params.file)
          self.hmiConnection:SendResponse(d2.id, d2.method, "SUCCESS", { })
          ptuSequence(self)
        end)
    end)
  self.mobileSession1:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

function Test:CheckStatus()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, { status = "UP_TO_DATE" })
end

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
