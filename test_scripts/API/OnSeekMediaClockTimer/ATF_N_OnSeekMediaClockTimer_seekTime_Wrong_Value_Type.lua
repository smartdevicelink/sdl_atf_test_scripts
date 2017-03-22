--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [MOBILE_API] New OnSeekMediaClockTimer notification
-- [HMI_API] New OnSeekMediaClockTimer notification
-- Processing invalid notifications from HMI that SDL should transfer to mobile app 
--
-- Description:
-- Parameters wrong type
-- [HMI_API] <param name="seekTime" type="Commom.TimeFormat" mandatory="true">
-- In case HMI sends invalid notification that SDL should transfer to mobile app, SDL must log the issue and ignore this notification.
--
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) OnSeekMediaClockTimer notification allowed in preloaded file for default app
-- c) App successfully registered, consented and activated
--
-- 2. Performed steps:
-- a) HMI sends OnSeekMediaClockTimer notification to SDL with wrong seekTime value type (string).
--
-- Expected result:
-- a) SDL does not resend OnSeekMediaClockTimer notification to mobile app.
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
  -- set permissions on OnSeekMediaClockTimer for default app
  data.policy_table.functional_groupings["Base-4"].rpcs["OnSeekMediaClockTimer"] = {hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}}  
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
function Test:TestStep_OnSeekMediaClockTimer_With_Wrong_seekTime_Value_Type()
 self.hmiConnection:SendNotification("UI.OnSeekMediaClockTimer",{seekTime =  "string", appID = self.applications["Test Application"]})
 EXPECT_NOTIFICATION("OnSeekMediaClockTimer"):Times(0)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

function Test.Postcondition_SDLStop()
  StopSDL()
end