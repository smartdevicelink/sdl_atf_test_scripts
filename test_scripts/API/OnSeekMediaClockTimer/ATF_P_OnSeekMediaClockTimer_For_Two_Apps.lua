--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [HMI_API] New OnSeekMediaClockTimer notification
-- [OnSeekMediaClockTimer] SDL must transfer notification to HMI in case it valid and allowed by Policies
--
-- Description:
-- <param name="appID" type="Integer" mandatory="true">
-- <description>The ID of application that relates to this mediaclock position change..</description>
-- In case
-- SDL receives OnSeekMediaClockTimer notification from HMI and this notification is valid and allowed by Policies
-- SDL must: transfer OnSeekMediaClockTimer notification from HMI to mobile app
--
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) OnSeekMediaClockTimer notification allowed in preloaded file for default app for all HMI levels
-- c) Apps successfully registered and consented
--
-- 2. Performed steps:
-- a) HMI sends OnSeekMediaClockTimer notification to SDL for both registered apps.
--
-- Expected result:
-- a) SDL resends OnSeekMediaClockTimer notification to appropriate mobile apps.
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')
local HMIApp2ID

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
    data.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
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
function Test:Preconditions_Activate_First_App()
commonSteps:ActivateAppInSpecificLevel(self, self.applications["Test Application"])
EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

function Test:Preconditions_Register_Second_App()
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession1:StartService(7)
  :Do(function (_,_)
      local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          HMIApp2ID = data.params.application.appID
        end)
      self.mobileSession1:ExpectResponse(correlationId, { success = true })
      end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_OnSeekMediaClockTimer_For_First_App()
 self.hmiConnection:SendNotification("UI.OnSeekMediaClockTimer",{seekTime =  {hours = 1, minutes = 1, seconds = 40}, appID = self.applications["Test Application"]})
 EXPECT_NOTIFICATION("OnSeekMediaClockTimer", {seekTime = {hours = 1, minutes = 1, seconds = 40}})
end

function Test:TestStep_OnSeekMediaClockTimer_For_Second_App()
 self.hmiConnection:SendNotification("UI.OnSeekMediaClockTimer",{seekTime =  {hours = 5, minutes = 5, seconds = 5}, appID = HMIApp2ID})
 self.mobileSession1:ExpectNotification("OnSeekMediaClockTimer", {seekTime = {hours = 5, minutes = 5, seconds = 5}})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

function Test.Postcondition_SDLStop()
  StopSDL()
end