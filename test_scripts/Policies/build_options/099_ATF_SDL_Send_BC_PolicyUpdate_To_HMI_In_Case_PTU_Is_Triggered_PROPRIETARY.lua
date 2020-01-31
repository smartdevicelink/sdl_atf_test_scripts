---------------------------------------------------------------------------------------------
-- PROPRIETARY flow
-- Requirement summary:
-- [PTU-Proprietary] Send BC.PolicyUpdate to HMI in case PTU is triggered
--
-- Description:
-- In case:
-- SDL is built with "-DEXTENDED_POLICY: ON" flag,
-- and PolicyTableUpdate is triggered
-- SDL must:
-- send BasicCommunication.PolicyUpdate ( <path to SnapshotPolicyTable>, <timeout from policies>, <set of retry timeouts>) to HMI.
-- reset the flag "UPDATE_NEEDED" to "UPDATING" (by sending OnStatusUpdate to HMI)
--
-- Steps:
-- 1. Register new app -> new PTU sequence started
-- 2. Verify response of BC.PolicyUpdate() request
-- 3. Verify status of SDL.OnStatusUpdate() notification
--
-- Expected result:
-- 2. Parameters (retry, timeout, file) are defined
-- 3. Status changed to 'UPDATING'
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")

--[[ Local Variables ]]
local sequence = { }
local r_expected_1 = {
  retry = { 1, 5, 25, 125, 625 },
  timeout = 60,
  file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" }
local r_actual_1 = { }
local r_expected_2 = { "UPDATE_NEEDED", "UPDATING" }
local r_actual_2 = { }

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
Test = require("connecttest")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: SDL.OnStatusUpdate()", d.params.status)
    table.insert(r_actual_2, d.params.status)
  end)
:Times(AnyNumber())
:Pin()

EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
:Do(function(_,data)
  r_actual_1 = data.params
  log("SDL->HMI: BC.PolicyUpdate()")
  Test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
:Times(AnyNumber())
:Pin()

-- --[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.Waiting()
  os.execute("sleep 1")
end

function Test.ShowSequence()
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

function Test:ValidatePolicyUpdate()
  if not is_table_equal(r_expected_1, r_actual_1) then
    local msg = table.concat({
        "\nExpected: ", commonFunctions:convertTableToString(r_expected_1, 1),
        "\nActual: ", commonFunctions:convertTableToString(r_actual_1, 1), "\n"})
    self:FailTestCase(msg)
  end
end

function Test:ValidateOnStatusUpdate()
  if not is_table_equal(r_expected_2, r_actual_2) then
    local msg = table.concat({
        "\nExpected: ", commonFunctions:convertTableToString(r_expected_2, 1),
        "\nActual: ", commonFunctions:convertTableToString(r_actual_2, 1), "\n"})
    self:FailTestCase(msg)
  end
end

return Test
