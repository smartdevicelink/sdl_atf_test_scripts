-- Requirement summary:
-- [PolicyTableUpdate] Apply PTU changes and OnPermissionChange notifying the apps
--
-- Description:
-- Right after the PoliciesManager merges the UpdatedPT with Local PT, it must apply the changes
-- and send onPermissionChange() notification to any registered mobile app in case the Updated PT
-- affected to this app`s policies.
-- app via OnSystemRequest() RPC.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- policyfile' corresponds to PTU validation rules
-- 2. Performed steps
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
--
-- Expected:
-- SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- SDL->app: onPermissionChange(permisssions)
---------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")

--[[ Local Variables ]]
local app_id = config.application1.registerAppInterfaceParams.fullAppID
local sequence = { }
local ptu_table

--[[ Local Functions ]]
local function timestamp()
  local f = io.popen("date +%H:%M:%S.%3N")
  local o = f:read("*all")
  f:close()
  return (o:gsub("\n", ""))
end

local function log(event, ...)
  table.insert(sequence, { ts = timestamp(), e = event, p = {...} })
end

local function show_log()
  print("--- Sequence -----------------------------------------------")
  for k, v in pairs(sequence) do
    local s = string.format("%03d", k) .. ": " .. v.ts .. ": " .. v.e
    for _, val in pairs(v.p) do
      if val then s = s .. ": " .. val end
    end
    print(s)
  end
  print("------------------------------------------------------------")
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
  --
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
  log("MOB->SDL: RQ: SystemRequest")
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(
    function(_, _)
      log("SDL->MOB: RS: SUCCESS: SystemRequest")
    end)
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
  log("MOB->SDL: RQ: RegisterAppInterface")

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      log("SDL->HMI: N: BC.OnAppRegistered")
      self.applications[config.application1.registerAppInterfaceParams.fullAppID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, {status = "UP_TO_DATE" })
      :Do(
        function(_, d2)
          log("SDL->HMI: N: SDL.OnStatusUpdate", d2.params.status)
        end)
      :Times(3)
      -- workaround due to issue in Mobile API: APPLINK-30390
      local onSystemRequestRecieved = false
      self.mobileSession:ExpectNotification("OnSystemRequest")
      :Do(
        function(_, d2)
          log("SDL->MOB: N: OnSystemRequest, RequestType: "..d2.payload.requestType )
          if (not onSystemRequestRecieved) and (d2.payload.requestType == "HTTP") then
            onSystemRequestRecieved = true
            ptu_table = json.decode(d2.binaryData)
            ptu(self)
          end
        end)
      :Times(2)
    end)

  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(
    function()
      log("SDL->MOB: RS: RegisterAppInterface")
      self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      :Do(
        function(_ ,d)
          log("SDL->MOB: N: OnHMIStatus", d.payload.hmiLevel)
        end)
    end)
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Do(
    function()
      log("SDL->MOB: N: OnPermissionsChange")
    end)
  :Times(2) -- 1st before update and 2nd after update
end

function Test.Test_ShowSequence()
  show_log()
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
