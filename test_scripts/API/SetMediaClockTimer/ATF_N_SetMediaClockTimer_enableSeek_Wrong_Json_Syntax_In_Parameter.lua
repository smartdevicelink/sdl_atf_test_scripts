--------------------------------------------------------------------------------------------
-- Requirement summary:
-- INVALID_DATA
--
-- Description:
-- In case the request comes to SDL with wrong json syntax, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
--
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) SetMediaClockTimer RPC allowed in preloaded file for default app
-- c) App successfylly registered, consented and activated
--
-- 2. Performed steps:
-- a) Sens SetMediaClockTimer request with with wrong json syntax in enableSeek
--
-- Expected result:
-- a) SDL respond with resultCode "INVALID_DATA" and success:"false"
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
    data.policy_table.functional_groupings["DataConsent-2"] = {rpcs = json.null}
  end
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
function Test:TestStep_SetMediaClockTimer_With_Wrong_Json_Syntax_in_enableSeek()
self.mobileSession.correlationId = self.mobileSession.correlationId + 1

        local msg =
        {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 0,
          rpcFunctionId    = 15, --SetMediaClockTimerID
          rpcCorrelationId = self.mobileSession.correlationId,
          -- missing ':' after "enableSeek"
          payload          = '{"startTime":{"seconds":34,"hours":0,"minutes":12},"endTime":{"seconds":33,"hours":11,"minutes":22},"updateMode":"COUNTUP", "enableSeek" true}'
        }
        self.mobileSession:Send(msg)

        self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

function Test.Postcondition_SDLStop()
  StopSDL()
end