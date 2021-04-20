----------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU-Proprietary] Transfer OnSystemRequest from HMI to mobile app
--
-- Description:
-- Preconditions:
-- 1. SDL is built with "DEXTENDED_POLICY: PRORPIETARY" flag.
-- 2. Trigger for PTU occurs
-- Steps:
-- 1. HMI->SDL: BC.OnSystemRequest(<path to UpdatedPT>, PROPRIETARY, params)
-- 2. Verify payload of SDL->MOB: OnSystemRequest() notification
--
-- Expected result:
-- Payload (Snapshot and Binary Header)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local json = require("modules/json")

--[[ Local Variables ]]
local sequence = { }
local f_name = os.tmpname()

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

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: SDL.OnStatusUpdate()", d.params.status)
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Test()
  local exp_service_id = 15
  local exp_body = '{ "policy_table": { } }'
  local exp_header = {
    ["ReadTimeout"] = 60,
    ["Content-Length"] = string.len(exp_body),
    ["charset"] = "utf-8",
    ["UseCaches"] = false,
    ["ConnectTimeout"] = 60,
    ["RequestMethod"] = "POST",
    ["ContentType"] = "application/json",
    ["InstanceFollowRedirects"] = false,
    ["DoInput"] = true,
    ["DoOutput"] = true
  }
  local f = io.open(f_name, "w")
  f:write(exp_body)
  f:close()

  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "PROPRIETARY", fileName = f_name, appID = self.applications["Test Application"] })
  self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
  :ValidIf(function(_, d)
      if d.serviceType ~= exp_service_id then
        local msg = table.concat({"Expected service Id: '", exp_service_id, "', actual: '", d.serviceType , "'"})
        return false, msg
      end
      local binary_data = json.decode(d.binaryData)
      local actual_header = binary_data["HTTPRequest"]["headers"]
      local actual_body = binary_data["HTTPRequest"]["body"]
      if not is_table_equal(exp_header, actual_header) then
        local msg = table.concat({
            "Header Expected:\n", commonFunctions:convertTableToString(exp_header, 1),
            "\nActual:\n", commonFunctions:convertTableToString(actual_header, 1)})
        return false, msg
      end
      if exp_body ~= actual_body then
        local msg = table.concat({"Body Expected:\n", exp_body, "\nActual:\n", actual_body})
        return false, msg
      end
      return true
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

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
