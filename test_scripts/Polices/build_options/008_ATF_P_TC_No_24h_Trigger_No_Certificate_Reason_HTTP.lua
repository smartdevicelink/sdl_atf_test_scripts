-- UNREADY - Securuty is not implemented in ATF according to
-- https://github.com/smartdevicelink/sdl_atf_test_scripts/pull/291/
--
---------------------------------------------------------------------------------------------
-- Requirement summary:
--[PTU]: In case module`s certificate does not exist in policies database the "24" hours
--trigger should not occur
--
-- Description:
--In case the module's certificate does not exist in policies database (example: first SDL run),
--the "24 hours" trigger should not occur.
-- 1. Used preconditions:
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- SDL and HMI are started and running
-- Policies database exists but without "certificate" in "module_config" section
-- App is registered
-- 2. Performed steps:
-- Mobile app sends StartService (<serviceType>, encrypted=true)
-- Trigger for certificate expiration status check is IGN_ON
-- PTU does not bring any certificate
--
-- Expected result:
-- In case "ForceProtectedService" is OFF,
-- (default value in ini file, [Security Manger] section is ForceProtectedService = Non)
-- SDL responds StartService (ACK, encrypted=false) to mobile app
-- SDL does not trigger "24 hours" update
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--TODO(mmihaylova): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]

commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_RegisterApp()
  local corr_id = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      self.HMIAppID = data.params.application.appID
    end)
  EXPECT_RESPONSE(corr_id, { success = true, resultCode = "SUCCESS"})
  :Do(function()
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN"})
    end)
  EXPECT_NOTIFICATION("OnPermissionsChange")
end

--[[ Test ]]

function Test.TestStep_PTU_Triggered_No_Certificate()
  return false
end

--[[ Postconditions ]]

commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
