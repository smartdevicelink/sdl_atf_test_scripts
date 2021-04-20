---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] "ccpu_version" obtaining via GetSystemInfo
--
-- Description:
-- Getting "ccpu_version" via GetSystemInfo on each SDL starts
-- 1. Used preconditions:
-- SDL and HMI are running
--
-- 2. Performed steps
-- Check policy table for 'ccpu_version'
--
-- Expected result:
-- SDL must request 'ccpu_version' parameter from HMI via GetSystemInfo HMI API;
-- SDL must request 'ccpu_version' ONLY once in ign cycle
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--[[ Precondition ]]
function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFileAndPolicyTable()
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_InitHMI()
  self:initHMI()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_SDL_sends_GetSystemInfo_on_InitHMI()
  self:initHMI_onReady()
  EXPECT_HMICALL("BasicCommunication.GetSystemInfo"):Times(AtLeast(1))
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.GetSystemInfo", "SUCCESS", {ccpu_version ="OpenS",
          language ="EN-US",wersCountryCode = "open_wersCountryCode"})
    end)
end

function Test:TestStep2_Check_ccpu_version_stored_in_PT()
  local query
  if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
    query = "sqlite3 " .. config.pathToSDL .. "storage/policy.sqlite".. " \"select ccpu_version from module_meta\""
  elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
    query = "sqlite3 " .. config.pathToSDL .. "policy.sqlite".. " \"select ccpu_version from module_meta\""
  else commonFunctions:userPrint(31, "policy.sqlite is not found")
  end

  if query ~= nil then
    os.execute("sleep 3")
    local handler = io.popen(query, 'r')
    os.execute("sleep 1")
    local result = handler:read( '*l' )
    handler:close()

    print("result: "..result)
    if result == "OpenS" then
      return true
    else
      self:FailTestCase("ccpu in DB has unexpected value: " .. tostring(result))
      return false
    end
  end
end

function Test:TestStep3_Check_ccpu_version_sent_on_RAI()
  self:connectMobile()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS", systemSoftwareVersion = "OpenS"})
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
