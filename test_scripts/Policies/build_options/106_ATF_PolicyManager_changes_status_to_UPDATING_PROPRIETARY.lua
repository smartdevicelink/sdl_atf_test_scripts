---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PoliciesManager changes status to "UPDATING"
-- [HMI API] OnStatusUpdate
--
-- Description:
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- PoliciesManager must change the status to "UPDATING" and notify HMI with OnStatusUpdate("UPDATING")
-- right after SnapshotPT is sent out to to mobile app via OnSystemRequest() RPC.
--
-- Steps:
-- 1. Register new app
-- 2. Trigger PTU
-- 3. SDL->HMI: Verify step of SDL.OnStatusUpdate(UPDATING) notification in PTU sequence
--
-- Expected result:
-- SDL.OnStatusUpdate(UPDATING) notification is send right after SDL->MOB: OnSystemRequest
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")

--[[ Local Variables ]]
local r_actual = { }
local r_expected = { "SDL.OnStatusUpdate(UPDATE_NEEDED)", "BC.PolicyUpdate", "SDL.OnStatusUpdate(UPDATING)"}

--[[ Local Functions ]]
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
Test = require("user_modules/connecttest_resumption")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RAI()
  self.mobileSession1:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      self.applications[config.application1.registerAppInterfaceParams.fullAppID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
      :Do(
        function(_, d2)
          table.insert(r_actual, "SDL.OnStatusUpdate(" .. d2.params.status .. ")")
        end)
      :Times(2)
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
      :Do(
        function(_, d3)
          self.hmiConnection:SendResponse(d3.id, d3.method, "SUCCESS", {})
          table.insert(r_actual, "BC.PolicyUpdate")
        end)
    end)
end

function Test:ValidateResult()
  if not is_table_equal(r_expected, r_actual) then
    local msg = table.concat({"\nExpected sequence:\n", commonFunctions:convertTableToString(r_expected, 1),
        "\nActual:\n", commonFunctions:convertTableToString(r_actual, 1)})
    self:FailTestCase(msg)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
