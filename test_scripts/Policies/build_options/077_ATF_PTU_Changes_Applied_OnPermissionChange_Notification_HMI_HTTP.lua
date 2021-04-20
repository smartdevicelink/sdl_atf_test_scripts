---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Notifying HMI via OnAppPermissionChanged about the affected application
--
-- Description:
-- PoliciesManager must initiate sending SDL.OnAppPermissionChanged{appID}
-- notification to HMI IN CASE the Updated PT resulted any changes in the appID app`s policies.
-- Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- policyfile' corresponds to PTU validation rules
-- 2. Performed steps
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- Expected:
-- SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- SDL replaces the following sections of the Local Policy Table with
-- the corresponding sections from PTU: module_config, functional_groupings andapp_policies
-- SDL removes 'policyfile' from the directory
-- SDL->app: onPermissionChange(<permisssionItem>)
-- SDL->HMI: SDL.OnAppPermissionChanged(appID, params)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

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
local function updatePTU(ptu)
  ptu.policy_table.consumer_friendly_messages.messages = nil
  ptu.policy_table.device_data = nil
  ptu.policy_table.module_meta = nil
  ptu.policy_table.vehicle_data = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies[app_id] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies[app_id]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.app_policies["0000001"]["RequestType"] = {"TRAFFIC_MESSAGE_CHANNEL", "PROPRIETARY", "HTTP", "QUERY_APPS"}
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  ptu.policy_table.module_config.preloaded_pt = nil
end

local function storePTUInFile(ptu, ptu_file_name)
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

local function ptu(self)
  local policy_file_name = "PolicyTableUpdate"
  local ptu_file_name = os.tmpname()
  updatePTU(ptu_table)
  storePTUInFile(ptu_table, ptu_file_name)
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, ptu_file_name)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  os.remove(ptu_file_name)
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RAI_PTU()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      self.applications[config.application1.registerAppInterfaceParams.fullAppID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, {status = "UP_TO_DATE" })
      :Times(3)
    end)

  local onSystemRequestRecieved = false
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(
    function(_, d2)
      if (not onSystemRequestRecieved) and (d2.payload.requestType == "HTTP") then
        onSystemRequestRecieved = true
        ptu_table = json.decode(d2.binaryData)
        ptu(self)
      end
    end)
  :Times(2)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(
    function()
      self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      self.mobileSession:ExpectNotification("OnPermissionsChange")
      :Times(2)
    end)

  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged")
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
