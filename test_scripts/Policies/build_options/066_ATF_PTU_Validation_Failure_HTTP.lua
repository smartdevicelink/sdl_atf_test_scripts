---------------------------------------------------------------------------------------------
-- HTTP flow
-- Requirements summary:
-- [PolicyTableUpdate] PTU validation failure
--
-- Description:
-- In case PTU validation fails, SDL must log the error locally and discard the policy table update
-- with No notification of Cloud about invalid data and
-- notify HMI with OnPolicyUpdate(UPDATE_NEEDED) .
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->MOB: OnSystemRequest()
-- SDL->HMI: SDL.OnStatusUpdate(UPDATING)
-- 2. Performed steps
-- MOB->SDL: SystemRequest(policy_file): policy_file with missing mandatory seconds_between_retries
--
-- Expected result:
-- SDL->HMI: OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

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
  -- remove mandatory field
  ptu.policy_table.module_config.seconds_between_retries = nil
end
local function storePTUInFile(ptu, ptu_file_name)
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

local function ptu(self)
  print("Start PTU")
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
  commonTestCases:DelayedExp(5000)
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  log("MOB->SDL: RQ: RegisterAppInterface")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      log("SDL->HMI: N: BC.OnAppRegistered")
      self.applications[config.application1.registerAppInterfaceParams.fullAppID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UPDATE_NEEDED" })
      :Do(
        function(_, d2)
          log("SDL->HMI: N: SDL.OnStatusUpdate", d2.params.status)
        end)
      :Times(3)
    end)

  -- workaround due to issue in Mobile API: APPLINK-30390
  local onSystemRequestRecieved = false

  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(
    function(_, d2)
      log("SDL->MOB: N: OnSystemRequest, RequestType: "..d2.payload.requestType )
      if (not onSystemRequestRecieved) and (d2.payload.requestType == "HTTP") then
        onSystemRequestRecieved = true
        --log("SDL->MOB: N: OnSystemRequest")
        ptu_table = json.decode(d2.binaryData)
        ptu(self)
      end
    end)
  :Times(2)

  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(
    function()
      log("SDL->MOB: RS: RegisterAppInterface")
      self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      :Do(
        function(_ ,d)
          log("SDL->MOB: N: OnHMIStatus", d.payload.hmiLevel)
        end)
      self.mobileSession:ExpectNotification("OnPermissionsChange")
      :Do(
        function()
          log("SDL->MOB: N: OnPermissionsChange")
        end)
      :Times(1)
    end)
end

function Test.ShowSequence()
  show_log()
end

function Test:Validate_LogFile()
  local log_file = "SmartDeviceLinkCore.log"
  local log_path = table.concat({ config.pathToSDL, "/", log_file })
  local exp_msg = "Errors: policy_table.policy_table.module_config.seconds_between_retries: object is not initialized"
  if not commonFunctions:read_specific_message(log_path, exp_msg) then
    local msg = table.concat({ "Expected error message was not found in ", log_file })
    self:FailTestCase(msg)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
