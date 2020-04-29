---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: UTF-8 encoding
--
-- Description:
-- The policy table variations must be authored in JSON (UTF-8 encoded).
--
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- LPT has non empty 'consumer_friendly_messages'
-- Register new app
-- Activate app
-- 2. Performed steps
-- 1. Perform PTU with specific data in UTF-8 format in 'consumer_friendly_messages' section
-- 2. After PTU is finished verify consumer_friendly_messages.messages section in LPT
--
-- Expected result:
-- The texts in Russian & Chinese in appropriate are parsed correctly by SDL
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
local json = require("modules/json")
local mobile_session = require('mobile_session')

--[[ Local Variables ]]
local db_file = config.pathToSDL .. "/" .. commonFunctions:read_parameter_from_smart_device_link_ini("AppStorageFolder") .. "/policy.sqlite"
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"
local f_name = os.tmpname()
local ptu
local sequence = { }
local request_http_received = false

--[[ Local Functions ]]
local function update_ptu()
  if(ptu == nil) then
    local config_path = commonPreconditions:GetPathToSDL()
    local pathToFile = config_path .. 'sdl_preloaded_pt.json'

    local file = io.open(pathToFile, "r")
    local json_data = file:read("*all")
    file:close()

    ptu = json.decode(json_data)
  end

  ptu.policy_table.device_data = nil
  ptu.policy_table.vehicle_data = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies["0000001"] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies["0000001"]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  -- updating specific parameters
  ptu.policy_table.consumer_friendly_messages.messages = {
    ["AppPermissions"] = { ["languages"] = { ["en-us"] = { }}},
    ["AppPermissionsHelp"] = { ["languages"] = { ["en-us"] = { }}}}
  ptu.policy_table.consumer_friendly_messages.messages["AppPermissions"]["languages"]["en-us"].tts = "表示您同意_1"
  ptu.policy_table.consumer_friendly_messages.messages["AppPermissions"]["languages"]["en-us"].label = "Метка"
  ptu.policy_table.consumer_friendly_messages.messages["AppPermissions"]["languages"]["en-us"].line1 = "LINE1"
  ptu.policy_table.consumer_friendly_messages.messages["AppPermissions"]["languages"]["en-us"].line2 = "LINE2"
  ptu.policy_table.consumer_friendly_messages.messages["AppPermissions"]["languages"]["en-us"].textBody = "TEXTBODY"
  ptu.policy_table.consumer_friendly_messages.messages["AppPermissionsHelp"]["languages"]["en-us"].tts = "授權請求_2"
end

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

local function execute_sqlite_query(file_db, query)
  if not file_db then
    return nil
  end
  local res = { }
  local file = io.popen(table.concat({"sqlite3 ", file_db, " '", query, "'"}), 'r')
  if file then
    for line in file:lines() do
      res[#res + 1] = line
    end
    file:close()
    return res
  else
    return nil
  end
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('cardinalities')
require("user_modules/AppTypes")

--[[ Specific Notifications ]]
function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup ("Preconditions")
function Test:Precondition_RegisterApp_trigger()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
  EXPECT_RESPONSE(CorIdRegister, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

  EXPECT_NOTIFICATION("OnSystemRequest")
  :Do(function(_, d)
      print("SDL->MOB: OnSystemRequest, requestType: "..d.payload.requestType)
      if(d.payload.requestType == "HTTP") then
        request_http_received = true
        ptu = json.decode(d.binaryData)
      end
    end)
  :Times(2)
end

function Test:CheckNotifications()
  if(request_http_received == false) then
    self:FailTestCase("OnSystemRequest with requestType = HTTP is not received at all")
  end
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.DeletePTUFile()
  if check_file_exists(policy_file_path .. "/" .. policy_file_name) then
    os.remove(policy_file_path .. "/" .. policy_file_name)
    print("Policy file is removed")
  end
end

function Test:ValidatePTS()
  if (ptu == nil) then
    self:FailTestCase("ptu is empty. Preloaded file will be used")
  else
    if ptu.policy_table.consumer_friendly_messages.messages then
      self:FailTestCase("Expected absence of 'consumer_friendly_messages.messages' section in PTS")
    end
  end
  update_ptu()
end

function Test:StorePTSInFile()
  if (ptu == nil) then
    self:FailTestCase("ptu is empty")
  else
    local f = io.open(f_name, "w")
    f:write(json.encode(ptu))
    f:close()
  end
end

function Test:Precondition_Successful_PTU()
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, f_name)
  log("MOB->SDL: SystemRequest")
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
  :Do(function(_, data)
      log(data.payload.resultCode .. ": SystemRequest")
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

-- Wait when policy db is updated
for i = 1, 1 do
  Test["Waiting " .. i * 5 .. " sec"] = function()
    os.execute("sleep 5")
  end
end

function Test:TestStep_ValidateResult()
  local r_expected = { "1|表示您同意_1|Метка|LINE1|LINE2|TEXTBODY|en-us|AppPermissions", "2|授權請求_2|||||en-us|AppPermissionsHelp" }
  local query = "select id, tts, label, line1, line2, textBody, language_code, message_type_name from message"
  local r_actual = execute_sqlite_query(db_file, query)
  if not is_table_equal(r_expected, r_actual) then
    local msg = table.concat({
        "\nExpected:\n", commonFunctions:convertTableToString(r_expected, 1),
        "\nActual:\n", commonFunctions:convertTableToString(r_actual, 1)})
    self:FailTestCase(msg)
  end
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
