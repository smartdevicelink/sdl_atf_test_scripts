--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GENIVI] SetMediaClockTimer: SDL must support new parameter "enableSeek"
--
-- Description:
-- SDL must support and process new "enableSeek" param at SetMediaClockTimer
--
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) SetMediaClockTimer RPC allowed in preloaded file for default app
-- c) App successfylly registered, consented and activated
--
-- 2. Performed steps:
-- a) Sens SetMediaClockTimer request with valid paremeters and valid enableSeek parameter
--
-- Expected result:
-- a) SDL successfylly transfer SetMediaClockTimer with enableSeek parameter to HMI and transfer SUCCESS resultCode to mobile
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ Local Functions ]]
local function ReplacePreloadedFile()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
end

local function RestorePreloadedPT()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
end

local function AddPermossionToPpreloadedFile()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = {rpcs = json.null}  end
  -- set permissions on SetMediaClockTimer for default app
  data.policy_table.functional_groupings["Base-4"].rpcs["SetMediaClockTimer"] = {hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}}  
  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
ReplacePreloadedFile()
AddPermossionToPpreloadedFile()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Preconditions_ActivateApp()
commonSteps:ActivateAppInSpecificLevel(self, self.applications["Test Application"])
EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_SetMediaClockTimer()
local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
            {
               startTime =
              {
                hours = 0,
                minutes = 1,
                seconds = 33
              },
              endTime =
              {
                hours = 0,
                minutes = 5,
                seconds = 35
              },
              updateMode = "COUNTUP",
              enableSeek = true
            })

EXPECT_HMICALL("UI.SetMediaClockTimer",
            {
              startTime =
              {
                hours = 0,
                minutes = 1,
                seconds = 33
              },
              endTime =
              {
                hours = 0,
                minutes = 5,
                seconds = 35
              },
              updateMode = "COUNTUP",
              enableSeek = true
            })
:Do(function(_,data)
self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
end)
EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

function Test.Postcondition_SDLStop()
  StopSDL()
end