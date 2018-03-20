--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [OnSeekMediaClockTimer] SDL must NOT transfer notification to HMI in case it valid and NOT allowed by Policies
--
-- Description:
-- In case
-- SDL receives OnSeekMediaClockTimer notification from HMI
-- and this notification is valid and NOT allowed by Policies
-- SDL must:
-- log corresponding error internally
-- ignore this OnSeekMediaClockTimer notification
-- SDL must NOT:
-- transfer OnSeekMediaClockTimer notification from HMI to mobile app
--
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) OnSeekMediaClockTimer notification disallowed in preloaded file for default app for all HMI levels
-- c) App successflly registered, consented and activated
--
-- 2. Performed steps:
-- a) HMI sends OnSeekMediaClockTimer notification to SDL in all HMI levels.
--
-- Expected result:
-- a) SDL does not resend OnSeekMediaClockTimer notification to mobile app for all HMI levels.
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
  -- remove permissions for OnSeekMediaClockTimer for default app
  data.policy_table.functional_groupings["Base-4"].rpcs["OnSeekMediaClockTimer"] = nil  
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
function Test:TestStep_No_OnSeekMediaClockTimer_When_App_In_FULL_HMI_Level()
 self.hmiConnection:SendNotification("UI.OnSeekMediaClockTimer",{seekTime =  {hours = 1, minutes = 1, seconds = 40}, appID = self.applications["Test Application"]})
 EXPECT_NOTIFICATION("OnSeekMediaClockTimer", {seekTime = {hours = 1, minutes = 1, seconds = 40}}):Times(0)
end

function Test:TestStep_Deactivate_App_To_LIMITED_HMI_Level_By_Sending_OnAppDeactivated_From_HMI()
self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",{reason = "GENERAL", appID = self.applications["Test Application"]})
EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "LIMITED"})
end

function Test:TestStep_No_OnSeekMediaClockTimer_When_App_In_LIMITED_HMI_Level()
 self.hmiConnection:SendNotification("UI.OnSeekMediaClockTimer",{seekTime =  {hours = 1, minutes = 1, seconds = 40}, appID = self.applications["Test Application"]})
 EXPECT_NOTIFICATION("OnSeekMediaClockTimer", {seekTime = {hours = 1, minutes = 1, seconds = 40}}):Times(0)
end

function Test:TestStep_Deactivate_App_To_BACKGROUND_HMI_Level_By_Sending_OnEventChanged_DEACTIVATE_HMI_True_From_HMI()
self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{eventName = "DEACTIVATE_HMI", isActive = true})
EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "BACKGROUND"})
end

function Test:TestStep_No_OnSeekMediaClockTimer_When_App_In_BACKGROUND_HMI_Level()
 self.hmiConnection:SendNotification("UI.OnSeekMediaClockTimer",{seekTime =  {hours = 1, minutes = 1, seconds = 40}, appID = self.applications["Test Application"]})
 EXPECT_NOTIFICATION("OnSeekMediaClockTimer", {seekTime = {hours = 1, minutes = 1, seconds = 40}}):Times(0)
end

function Test:TestStep_Deactivate_App_To_NONE_HMI_Level_By_Sending_OnExitApplication_USER_EXIT_From_HMI()
self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{reason = "USER_EXIT", appID = self.applications["Test Application"]})
EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})
end

function Test:TestStep_No_OnSeekMediaClockTimer_When_App_In_NONE_HMI_Level()
 self.hmiConnection:SendNotification("UI.OnSeekMediaClockTimer",{seekTime =  {hours = 1, minutes = 1, seconds = 40}, appID = self.applications["Test Application"]})
 EXPECT_NOTIFICATION("OnSeekMediaClockTimer", {seekTime = {hours = 1, minutes = 1, seconds = 40}}):Times(0)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

function Test.Postcondition_SDLStop()
  StopSDL()
end