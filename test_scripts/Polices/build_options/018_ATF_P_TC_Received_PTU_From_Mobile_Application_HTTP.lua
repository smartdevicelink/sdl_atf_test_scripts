-- HTTP flow
-- Requirements summary:
-- [PolicyTableUpdate] Got PTU from mobile application
-- [HMI API] SystemRequest request/response
--
-- Description:
-- Upon receiving the response (before timeout) from the application via SystemRequest,
-- SDL must stop the timer of PTU "timeout" and Base64-decode the payload,
-- which is the Policy Table Update.
--
-- Preconditions:
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered
-- PTU is requested
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->MOB: OnSystemRequest()
-- Steps:
-- app->SDL:SystemRequest(requestType=HTTP)
--
-- Expected result:
-- LPT is updated successfully
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
-- local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")

--[[ Local Variables ]]
local sequence = { }
local f_name = os.tmpname()
local pts
local actual_request_type

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

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: SDL.OnStatusUpdate()", d.params.status)
  end)
:Times(AnyNumber())
:Pin()

function Test:RegisterNotification()
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      log("SDL->MOB: OnSystemRequest()", d.payload.requestType, d.payload.url)
      pts = json.decode(d.binaryData)
      actual_request_type = d.payload.requestType
    end)
  :Times(AnyNumber())
  :Pin()
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ValidatePTS()
  if pts.policy_table.consumer_friendly_messages.messages then
    self:FailTestCase("Expected absence of 'consumer_friendly_messages.messages' section in PTS")
  end
end

function Test.UpdatePTS()
  pts.policy_table.device_data = nil
  pts.policy_table.usage_and_error_counts = nil
  pts.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE"
  }
  pts.policy_table.app_policies["0000001"]["groups"] = { "Base-4", "Base-6" }
  pts.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
end

function Test.StorePTSInFile()
  local f = io.open(f_name, "w")
  f:write(json.encode(pts))
  f:close()
end

function Test:Update_LPT()
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = "PolicyTableUpdate" }, f_name)
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
end

function Test.Test_ShowSequence()
  show_log()
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test:Validate_OnSystemRequest()
  local expected_request_type = "HTTP"
  if expected_request_type ~= actual_request_type then
    local msg = table.concat({
        "\nExpected OnSystemRequest() type is '", expected_request_type,
        "'\nActual: '", actual_request_type, "'"})
    self:FailTestCase(msg)
  end
end

function Test.Clean()
  os.remove(f_name)
end

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
