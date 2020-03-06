---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] OnStatusUpdate trigger
-- [HMI API] OnStatusUpdate
--
-- Description:
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- PoliciesManager must notify HMI via SDL.OnStatusUpdate notification right after one of the statuses
-- of UPDATING, UPDATE_NEEDED and UP_TO_DATE is changed from one to another.
--
-- Steps:
-- 1. Register new app1
-- 2. SDL->HMI: Verify status of SDL.OnStatusUpdate notification
-- 3. Trigger PTU
-- 4. Register new app2
--
-- Expected result:
-- Status changes in a following way:
-- "UPDATE_NEEDED" -> "UPDATING" -> "UP_TO_DATE" -> "UPDATE_NEEDED" -> "UPDATING"
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")

--[[ Local Variables ]]
local sequence = { }

local app_id = config.application1.registerAppInterfaceParams.fullAppID

local policy_file_name = "PolicyTableUpdate"
local pts_file_name = "sdl_snapshot.json"
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local ptu_table
local r_expected = { "UPDATE_NEEDED", "UPDATING", "UP_TO_DATE", "UPDATE_NEEDED", "UPDATING" }
local r_actual = { }

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

local function is_table_equal(t1, t2)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not is_table_equal(v1, v2) then return false end
  end
  for k2, v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not is_table_equal(v1, v2) then return false end
  end
  return true
end

local function check_file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

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
  ptu.policy_table.vehicle_data = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies[app_id] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies[app_id]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  --
  -- ptu.policy_table.app_policies[app_id].default_hmi = "BACKGROUND"
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
Test = require("user_modules/connecttest_resumption")
require("user_modules/AppTypes")

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: N: SDL.OnStatusUpdate", d.params.status)
    table.insert(r_actual, d.params.status)
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.DeleteFiles()
  if check_file_exists(policy_file_path .. "/" .. policy_file_name) then
    os.remove(policy_file_path .. "/" .. policy_file_name)
    print("Policy file removed")
  end
  if check_file_exists(policy_file_path .. "/" .. pts_file_name) then
    os.remove(policy_file_path .. "/" .. pts_file_name)
    print("PTS file removed")
  end
end

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:StartNewSession()
  self.mobileSession = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RegisterNewApp()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, d)
      log("SDL->HMI: RQ: BC.PolicyUpdate")
      Test.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      log("HMI->SDL: RS: BC.PolicyUpdate")
      if not ptu_table then
        ptu_table = ptsToTable(d.params.file)
      end
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:PTU()
  if ptu_table then
    local ptu_file_name = os.tmpname()
    local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })
    log("HMI->SDL: RQ: SDL.GetPolicyConfigurationData")
    EXPECT_HMIRESPONSE(requestId)
    :Do(function()
        log("SDL->HMI: RS: SDL.GetPolicyConfigurationData")
        self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name})
        log("HMI->SDL: N: BC.OnSystemRequest")
        updatePTU(ptu_table)
        storePTUInFile(ptu_table, ptu_file_name)
        EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
        :Do(function()
            log("SDL->MOB: N: OnSystemRequest")
            local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name}, ptu_file_name)
            log("MOB->SDL: RQ: SystemRequest")
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d)
                log("SDL->HMI: RQ: BC.SystemRequest")
                self.hmiConnection:SendResponse(d.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                log("HMI->SDL: RS: SUCCESS: BC.SystemRequest")
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
                log("HMI->SDL: N: SDL.OnReceivedPolicyUpdate")
              end)
            EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
            log("SDL->MOB: RS: SUCCESS: SystemRequest")
          end)
      end)
    os.remove(ptu_file_name)
  end
end

function Test:CheckStatus()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  log("HMI->SDL: RQ: SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, { status = "UP_TO_DATE" })
  log("HMI->SDL: RS: UP_TO_DATE: SDL.GetStatusUpdate")
end

function Test:StartNewSession2()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterNewApp2()
  local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  self.mobileSession2:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, d)
    log("SDL->HMI: RQ: BC.PolicyUpdate")
      Test.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      log("HMI->SDL: RS: BC.PolicyUpdate")
    end)
end

for i = 1, 3 do
  Test["Waiting " .. i .. " sec"] = function()
    os.execute("sleep 1")
  end
end

function Test.Test_ShowSequence()
  show_log()
end

function Test:ValidateResult()
  if not is_table_equal(r_actual, r_expected) then
    local msg = table.concat({
        "\nExpected sequence:\n", commonFunctions:convertTableToString(r_expected, 1),
        "\nActual:\n", commonFunctions:convertTableToString(r_actual, 1) })
    self:FailTestCase(msg)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
