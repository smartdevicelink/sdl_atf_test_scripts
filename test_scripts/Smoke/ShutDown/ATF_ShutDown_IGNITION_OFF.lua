-- Requirement summary:
-- [Data Resumption]:OnExitAllApplications(IGNITION_OFF) in terms of resumption
--
-- Description:
-- In case SDL receives OnExitAllApplications(IGNITION_OFF),
-- SDL must clean up any resumption-related data
-- Obtained after OnExitAllApplications( SUSPEND). SDL must stop all its processes,
-- notify HMI via OnSDLClose and shut down.
--
-- 1. Used preconditions
-- HMI is running
-- One App is registered and activated on HMI
--
-- 2. Performed steps
-- Perform ignition Off
-- HMI sends OnExitAllApplications(IGNITION_OFF)
--
-- Expected result:
-- 1. SDL sends to App OnAppInterfaceUnregistered
-- 2. SDL sends to HMI OnSDLClose and stops working
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local SDL = require('SDL')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

function Test:Start_SDL_With_One_Activated_App()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          self:startSession():Do(function ()
            commonSteps:ActivateAppInSpecificLevel(self,
              self.applications[config.application1.registerAppInterfaceParams.appName])
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
          end)
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Check that SDL finish it's work properly by IGNITION_OFF")
function Test:ShutDown_IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    SDL:DeleteFile()
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
    :Do(function()
        SDL:StopSDL()
      end)
  end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
