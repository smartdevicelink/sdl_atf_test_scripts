---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Notifying HMI via OnAppPermissionChanged about the
--affected application
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
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")

--[[ Local Variables ]]
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"
local f_name = os.tmpname()
local ptu
local sequence = { }

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
  print("--- Sequence -------------------------------------")
  for k, v in pairs(sequence) do
    local s = k .. ": " .. v.ts .. ": " .. v.e
    for _, val in pairs(v.p) do
      if val then s = s .. ": " .. val end
    end
    print(s)
  end
  print("--------------------------------------------------")
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

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require("connecttest")
require('cardinalities')
require("user_modules/AppTypes")

--[[ Specific Notifications ]]
function Test:RegisterNotification()
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      log("SDL->MOB: OnSystemRequest")
      ptu = json.decode(d.binaryData)
    end)
  :Times(AtLeast(1))
  :Pin()
end

EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: SDL.OnStatusUpdate", d.params.status)
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.DeletePTUFile()
  if check_file_exists(policy_file_path .. "/" .. policy_file_name) then
    os.remove(policy_file_path .. "/" .. policy_file_name)
    print("Policy file is removed")
  end
end

function Test:ValidatePTS()
  if ptu.policy_table.consumer_friendly_messages.messages then
    self:FailTestCase("Expected absence of 'consumer_friendly_messages.messages' section in PTS")
  end
end

function Test.UpdatePTS()
  ptu.policy_table.device_data = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies["0000001"] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies["0000001"]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
end

function Test.StorePTSInFile()
  local f = io.open(f_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:PTU()
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, f_name)
  log("MOB->SDL: SystemRequest")
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Do(function()
      log("SDL->MOB: OnPermissionsChange")
    end)
  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged")
  :Do(function()
      log("SDL->HMI: SDL.OnAppPermissionChanged")
    end)
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      log("SUCCESS: SystemRequest")
    end)
end

function Test.Test_ShowSequence()
  show_log()
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Clean()
  os.remove(f_name)
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
